#!/usr/bin/env bash
#
# tor-control — Tor ControlPort (9051) yöneticisi, gum tabanlı TUI
#
#   /etc/tor/torrc içine ControlPort + kimlik doğrulama satırlarını ekler ya da
#   kaldırır, NEWNYM (yeni devre) sinyali gönderir.
#
#   Güvenlik: her yazma öncesi torrc yedeklenir, "tor --verify-config" ile
#   doğrulanır; geçersizse ya da servis kalkmazsa yedek otomatik geri yüklenir.
#   HTTPSProxy / SocksPort gibi mevcut satırlara dokunulmaz.
#
#   NOT: tornet 2.0.2 IP rotasyonunu ControlPort ile DEĞİL, "systemctl reload tor"
#   ile yapıyor (tornet.py: change_ip -> service_action("reload")). Yani ControlPort
#   tornet için gerekli değil; nyx, stem ve buradaki NEWNYM için gerekli — ve
#   reload'a göre çok daha hızlıdır.
#
# Kullanım:
#   tor-control              menü (gum TUI)
#   tor-control status       durum
#   tor-control on-pass      parola kimlik doğrulaması ile aç
#   tor-control on-cookie    cookie kimlik doğrulaması ile aç
#   tor-control off          kaldır
#   tor-control newnym       yeni devre iste

set -uo pipefail

TORRC="/etc/tor/torrc"
BACKUP="/etc/tor/torrc.tor-control.bak"
CTRL_HOST="127.0.0.1"
CTRL_PORT="9051"
SOCKS_PORT="9050"
COOKIE="/var/lib/tor/control_auth_cookie"
PW_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/tor-control"
PW_FILE="$PW_DIR/password"

# ─── gum yardımcıları ────────────────────────────────────────────────────────
C_OK=42; C_ERR=203; C_WARN=214; C_ACC=212; C_DIM=245

command -v gum >/dev/null 2>&1 || {
    echo "gum kurulu değil:  sudo pacman -S gum" >&2
    exit 1
}

title() { gum style --border double --border-foreground $C_ACC --padding "0 2" --margin "1 0" --bold "$1"; }
ok()    { gum style --foreground $C_OK   "  ✔ $1"; }
err()   { gum style --foreground $C_ERR  "  ✘ $1"; }
warn()  { gum style --foreground $C_WARN "  ! $1"; }
info()  { gum style --foreground $C_DIM  "    $1"; }

# ─── torrc işlemleri ─────────────────────────────────────────────────────────
need_sudo() {
    sudo -n true 2>/dev/null && return 0
    info "sudo yetkisi gerekiyor."
    sudo -v || { err "sudo alınamadı."; return 1; }
}

backup_torrc()  { sudo cp -a "$TORRC" "$BACKUP"; }
restore_torrc() { sudo cp -a "$BACKUP" "$TORRC"; }

# Sadece bu script'in yönettiği satırları siler; başka hiçbir şeye dokunmaz.
strip_control_lines() {
    sudo sed -i \
        -e '/^ControlPort/d' \
        -e '/^CookieAuthentication/d' \
        -e '/^CookieAuthFileGroupReadable/d' \
        -e '/^DataDirectoryGroupReadable/d' \
        -e '/^HashedControlPassword/d' \
        "$TORRC"
}

verify_and_apply() {
    if ! sudo tor --verify-config -f "$TORRC" >/dev/null 2>&1; then
        err "torrc geçersiz! Yedek geri yükleniyor."
        restore_torrc
        err "Değişiklik iptal edildi."
        return 1
    fi
    gum spin --spinner dot --title "Tor yeniden başlatılıyor..." -- sudo systemctl restart tor
    if ! systemctl is-active --quiet tor; then
        err "Tor başlatılamadı! Yedek geri yükleniyor."
        restore_torrc
        sudo systemctl restart tor
        info "Log:  journalctl -u tor -n 30"
        return 1
    fi
    return 0
}

wait_for_ctrl_port() {
    local i
    for i in $(seq 1 20); do
        ss -ltn 2>/dev/null | grep -q "$CTRL_HOST:$CTRL_PORT" && return 0
        sleep 0.5
    done
    return 1
}

control_enabled() { grep -q '^ControlPort' "$TORRC" 2>/dev/null; }

# ─── AÇ: parola kimlik doğrulaması ───────────────────────────────────────────
enable_password() {
    title "ControlPort aç — parola kimlik doğrulaması"

    local pw pw2 hash
    pw=$(gum input --password --header "Kontrol parolası belirle" --placeholder "parola") || return 1
    [ -z "$pw" ] && { err "Parola boş olamaz."; return 1; }
    pw2=$(gum input --password --header "Parolayı tekrar gir" --placeholder "parola") || return 1
    [ "$pw" != "$pw2" ] && { err "Parolalar eşleşmiyor."; return 1; }

    hash=$(tor --hash-password "$pw" 2>/dev/null | tail -1)
    case "$hash" in
        16:*) ;;
        *) err "Parola hash'lenemedi."; return 1 ;;
    esac

    need_sudo || return 1
    backup_torrc
    strip_control_lines
    printf 'ControlPort %s:%s\nHashedControlPassword %s\n' "$CTRL_HOST" "$CTRL_PORT" "$hash" \
        | sudo tee -a "$TORRC" >/dev/null

    verify_and_apply || return 1

    mkdir -p "$PW_DIR"
    ( umask 077; printf '%s' "$pw" > "$PW_FILE" )
    chmod 600 "$PW_FILE"

    if wait_for_ctrl_port; then
        ok "ControlPort açık: $CTRL_HOST:$CTRL_PORT (parola)"
    else
        warn "torrc yazıldı ama $CTRL_PORT henüz dinlenmiyor."
    fi
    info "Parola düz metin saklandı: $PW_FILE (chmod 600)"
    info "Silmek için: tor-control off"
}

# ─── AÇ: cookie kimlik doğrulaması ───────────────────────────────────────────
enable_cookie() {
    title "ControlPort aç — cookie kimlik doğrulaması"
    info "Cookie dosyası /var/lib/tor/ altında ve dizin 0700 tor:tor."
    info "Okuyabilmen için 'tor' grubuna eklenmen ve OTURUMU YENİDEN AÇMAN gerekir."
    info "Hemen çalışan bir çözüm istiyorsan parola modunu seç."
    gum confirm "Cookie modu ile devam edilsin mi?" || return 1

    need_sudo || return 1
    backup_torrc
    strip_control_lines
    printf 'ControlPort %s:%s\nCookieAuthentication 1\nCookieAuthFileGroupReadable 1\nDataDirectoryGroupReadable 1\n' \
        "$CTRL_HOST" "$CTRL_PORT" | sudo tee -a "$TORRC" >/dev/null

    verify_and_apply || return 1

    if ! id -nG | tr ' ' '\n' | grep -qx tor; then
        if gum confirm "Kullanıcı '$USER' 'tor' grubuna eklensin mi?"; then
            if sudo usermod -aG tor "$USER"; then
                warn "Eklendi — etkili olması için çıkış/giriş yapmalısın."
                info "O zamana kadar NEWNYM cookie'yi sudo ile okuyacak."
            else
                err "Gruba eklenemedi."
            fi
        fi
    fi

    if wait_for_ctrl_port; then
        ok "ControlPort açık: $CTRL_HOST:$CTRL_PORT (cookie)"
    else
        warn "torrc yazıldı ama $CTRL_PORT henüz dinlenmiyor."
    fi
}

# ─── KAPAT ───────────────────────────────────────────────────────────────────
disable_control() {
    title "ControlPort kapat"

    if ! control_enabled; then
        warn "ControlPort zaten tanımlı değil."
        [ -f "$PW_FILE" ] && { rm -f "$PW_FILE"; info "Artık kullanılmayan parola dosyası silindi."; }
        return 0
    fi

    info "Silinecek satırlar:"
    grep -E '^(ControlPort|CookieAuthentication|CookieAuthFileGroupReadable|DataDirectoryGroupReadable|HashedControlPassword)' \
        "$TORRC" | gum style --foreground $C_DIM --padding "0 4"
    gum confirm "Bu satırlar torrc'den silinsin mi?" || { info "İptal edildi."; return 1; }

    need_sudo || return 1
    backup_torrc
    strip_control_lines
    verify_and_apply || return 1

    [ -f "$PW_FILE" ] && { rm -f "$PW_FILE"; info "Saklanan kontrol parolası silindi."; }

    ok "ControlPort kapatıldı."
    info "HTTPSProxy / SocksPort satırlarına dokunulmadı."
}

# ─── DURUM ───────────────────────────────────────────────────────────────────
status() {
    title "Durum"

    local svc
    svc=$(systemctl is-active tor 2>/dev/null)
    if [ "$svc" = "active" ]; then ok "tor servisi: active"; else err "tor servisi: ${svc:-bilinmiyor}"; fi

    if control_enabled; then
        ok "torrc: $(grep -m1 '^ControlPort' "$TORRC")"
        if grep -q '^HashedControlPassword' "$TORRC"; then
            info "kimlik doğrulama: parola"
            [ -r "$PW_FILE" ] && info "parola dosyası: $PW_FILE" || warn "parola dosyası yok — NEWNYM elle parola soracak"
        elif grep -q '^CookieAuthentication 1' "$TORRC"; then
            info "kimlik doğrulama: cookie"
            id -nG | tr ' ' '\n' | grep -qx tor \
                && info "'tor' grubu: üyesin" \
                || warn "'tor' grubunda değilsin — cookie sudo ile okunacak"
        else
            warn "kimlik doğrulama satırı yok — ControlPort açık ama kilitsiz olabilir"
        fi
    else
        warn "torrc: ControlPort tanımlı değil"
    fi

    if grep -q '^HTTPSProxy' "$TORRC"; then
        info "upstream: $(grep -m1 '^HTTPSProxy' "$TORRC")"
    else
        warn "upstream proxy yok — PdaNet modundaysan önce 'http_tor' çalıştır"
    fi

    ss -ltn 2>/dev/null | grep -q "$CTRL_HOST:$CTRL_PORT" \
        && ok "port $CTRL_PORT (control): dinleniyor" \
        || err "port $CTRL_PORT (control): kapalı"
    ss -ltn 2>/dev/null | grep -q "$CTRL_HOST:$SOCKS_PORT" \
        && ok "port $SOCKS_PORT (socks): dinleniyor" \
        || warn "port $SOCKS_PORT (socks): kapalı"
}

# ─── NEWNYM ──────────────────────────────────────────────────────────────────
auth_line() {
    if grep -q '^HashedControlPassword' "$TORRC"; then
        local pw
        if [ -r "$PW_FILE" ]; then
            pw=$(cat "$PW_FILE")
        else
            pw=$(gum input --password --header "Kontrol parolası" --placeholder "parola") || return 1
        fi
        [ -z "$pw" ] && return 1
        printf 'AUTHENTICATE "%s"' "$pw"
    elif grep -q '^CookieAuthentication 1' "$TORRC"; then
        local hex=""
        if [ -r "$COOKIE" ]; then
            hex=$(xxd -p -c 256 "$COOKIE" 2>/dev/null)
        else
            hex=$(sudo xxd -p -c 256 "$COOKIE" 2>/dev/null)
        fi
        [ -z "$hex" ] && return 1
        printf 'AUTHENTICATE %s' "$hex"
    else
        return 1
    fi
}

newnym() {
    title "NEWNYM — yeni devre"

    if ! ss -ltn 2>/dev/null | grep -q "$CTRL_HOST:$CTRL_PORT"; then
        err "ControlPort ($CTRL_PORT) dinlenmiyor. Önce aç."
        return 1
    fi

    local auth
    auth=$(auth_line) || { err "Kimlik doğrulama bilgisi alınamadı."; return 1; }

    exec 3<>"/dev/tcp/$CTRL_HOST/$CTRL_PORT" 2>/dev/null || {
        err "$CTRL_HOST:$CTRL_PORT adresine bağlanılamadı."
        return 1
    }
    printf '%s\r\nSIGNAL NEWNYM\r\nQUIT\r\n' "$auth" >&3
    local resp
    resp=$(timeout 5 cat <&3)
    exec 3>&-
    exec 3<&-

    if printf '%s' "$resp" | grep -qE '^(515|514)|Authentication failed'; then
        err "Kimlik doğrulama başarısız."
        info "Parola değiştiyse:  tor-control off  ardından  tor-control on-pass"
        return 1
    fi

    if [ "$(printf '%s' "$resp" | grep -c '^250')" -ge 2 ]; then
        ok "Yeni devre istendi (SIGNAL NEWNYM)."
        gum confirm "Yeni çıkış IP'si sorgulansın mı?" || return 0
        local out
        out=$(gum spin --show-output --spinner dot --title "check.torproject.org sorgulanıyor..." -- \
              curl -s --max-time 25 --socks5-hostname "$CTRL_HOST:$SOCKS_PORT" \
              https://check.torproject.org/api/ip)
        if [ -n "$out" ]; then ok "$out"; else err "IP alınamadı — devre henüz kurulmamış olabilir."; fi
    else
        err "Beklenmeyen yanıt:"
        printf '%s\n' "$resp" | gum style --foreground $C_DIM --padding "0 4"
        return 1
    fi
}

# ─── Menü ────────────────────────────────────────────────────────────────────
menu() {
    while true; do
        clear
        title "🧅 Tor ControlPort Yöneticisi"
        if control_enabled; then
            gum style --foreground $C_OK "  torrc: ControlPort AÇIK"
        else
            gum style --foreground $C_WARN "  torrc: ControlPort KAPALI"
        fi

        local choice
        choice=$(gum choose --header "" \
            "Durum" \
            "Aç — parola auth (önerilen)" \
            "Aç — cookie auth" \
            "NEWNYM (yeni devre)" \
            "Kapat" \
            "Çıkış") || exit 0

        case "$choice" in
            Durum*)         status ;;
            "Aç — parola"*) enable_password ;;
            "Aç — cookie"*) enable_cookie ;;
            NEWNYM*)        newnym ;;
            Kapat*)         disable_control ;;
            *)              exit 0 ;;
        esac

        echo
        gum confirm --affirmative "Menü" --negative "Çık" "Devam?" || exit 0
    done
}

# ─── Giriş ───────────────────────────────────────────────────────────────────
[ -f "$TORRC" ] || { err "$TORRC bulunamadı. tor kurulu mu?"; exit 1; }

case "${1:-}" in
    ""|menu)     menu ;;
    status)      status ;;
    on-pass)     enable_password ;;
    on-cookie)   enable_cookie ;;
    off)         disable_control ;;
    newnym)      newnym ;;
    -h|--help|help)
        printf 'kullanım: %s [menu|status|on-pass|on-cookie|off|newnym]\n' "${0##*/}" ;;
    *)
        err "Bilinmeyen komut: $1"
        printf 'kullanım: %s [menu|status|on-pass|on-cookie|off|newnym]\n' "${0##*/}" >&2
        exit 1 ;;
esac
