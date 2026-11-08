# 30-proxy — proxy and Tor.
#
# Everything lives in `proxyctl` (~/.local/bin/proxyctl); the address is in
# ~/.config/proxyctl/config. The functions here exist only because a script
# cannot change the calling shell's environment: they eval `proxyctl env`.

# ── the current shell's env ──────────────────────────────────────────────────
proxy_on() {
    local exports
    exports="$(proxyctl env proxy)" || return 1
    eval "$exports"
    echo "✅ Proxy active: $(proxyctl addr)"
}

proxy_off() {
    eval "$(proxyctl env off)"
    echo "🚫 Proxy off."
}

tor_on() {
    eval "$(proxyctl env tor)"
    echo "🧅 Tor proxy active: 127.0.0.1:9050"
}

tor_off() { proxy_off }

# ── system and Tor: thin aliases over proxyctl ──────────────────────────────
alias proxy_status='proxyctl status'
alias tunnel_on='proxyctl system proxy'     # all TCP through the phone proxy
alias tunnel_off='proxyctl system normal'
alias tunnel_status='proxyctl status'
alias http_tor='proxyctl tor exit proxy'    # tor reaches its relays via the phone proxy
alias normal_tor='proxyctl tor exit direct'
alias tor_check='proxyctl status'
alias trnt='proxyctl tor rotate'            # trnt 20 = new identity every 20 s, trnt off
alias torb='proxyctl browser'               # Tor Browser over the system Tor

# ── proxychains ──────────────────────────────────────────────────────────────
alias pc='proxychains'
alias pct='proxychains -f ~/.proxychains/tor.conf'   # through Tor (SOCKS5 9050)
alias vmproxy='sudo /usr/local/bin/vm-proxy'         # VM proxy: on/off/status/test

# ── proxy config files ───────────────────────────────────────────────────────
alias pconfig='sudo nvim /etc/proxychains.conf'
alias tconfig='sudo nvim /etc/tor/torrc'
