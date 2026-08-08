# 30-proxy — proxy and Tor.
#
# The functions here are ONLY the ones that change the current shell's environment
# variables; a script cannot do that (a subprocess cannot touch the parent's env).
# Everything that touches persistent configuration lives in the shared scripts:
#
#   net-proxy  git|docker|ssh|sart on|off   →  ~/.local/bin/net-proxy
#   net-tunnel on|off|status|check          →  ~/.local/bin/net-tunnel
#   tor-net    proxy|direct|check|status    →  ~/.local/bin/tor-net
#   tor-control                             →  ControlPort / NEWNYM
#
# The address comes from $PROXY_ADDR in 00-env.zsh.

# ── the current shell's env ──────────────────────────────────────────────────
proxy_on() {
    local url="http://${PROXY_ADDR}"
    export http_proxy="$url" https_proxy="$url" ftp_proxy="$url"
    export HTTP_PROXY="$url" HTTPS_PROXY="$url"
    export no_proxy="localhost,127.0.0.1,::1,.local"
    export NO_PROXY="$no_proxy"
    echo "✅ Proxy active: $PROXY_ADDR"
}

proxy_off() {
    unset http_proxy https_proxy ftp_proxy all_proxy no_proxy
    unset HTTP_PROXY HTTPS_PROXY FTP_PROXY ALL_PROXY NO_PROXY
    echo "🚫 Proxy off."
}

tor_on() {
    local url="socks5h://127.0.0.1:9050"
    export http_proxy="$url" https_proxy="$url" ftp_proxy="$url" all_proxy="$url"
    export HTTP_PROXY="$url" HTTPS_PROXY="$url" FTP_PROXY="$url" ALL_PROXY="$url"
    export no_proxy="localhost,127.0.0.1,::1,.local"
    export NO_PROXY="$no_proxy"
    echo "🧅 Tor proxy active: 127.0.0.1:9050"
}

tor_off() { proxy_off }

# Which proxy is on?
proxy_status() { net-proxy status }

# ── persistent settings: thin wrappers around the shared scripts ─────────────
# (the old names are kept so muscle memory keeps working)
alias gitproxy_on='net-proxy git on'
alias gitproxy_off='net-proxy git off'
alias docker_proxy_on='net-proxy docker on'
alias docker_proxy_off='net-proxy docker off'
alias ssh_proxy_on='net-proxy ssh on'
alias ssh_proxy_off='net-proxy ssh off'
alias sart_proxy_on='net-proxy sart on'
alias sart_proxy_off='net-proxy sart off'

alias http_tor='tor-net proxy'      # route Tor out via the phone proxy
alias normal_tor='tor-net direct'   # go back to a direct connection
alias tor_check='tor-net check'

# ── transparent tunnel (Steam, Proton, 32-bit, containers) ───────────────────
# proxychains cannot reach those — see the header of net-tunnel. With this on,
# plain `steam` works; no `pc steam`.
alias tunnel_on='net-tunnel on'
alias tunnel_off='net-tunnel off'
alias tunnel_status='net-tunnel status'
alias tunnel_check='net-tunnel check'

# ── proxychains / tornet ─────────────────────────────────────────────────────
alias pc='proxychains'
alias pct='proxychains -f ~/.proxychains/tor.conf'   # through Tor (SOCKS5 9050)
alias trnt='tornet --count 0 --interval'
alias vmproxy='sudo /usr/local/bin/vm-proxy'         # VM proxy: on/off/status/test

# ── proxy config files ───────────────────────────────────────────────────────
alias pconfig='sudo nvim /etc/proxychains.conf'
alias tconfig='sudo nvim /etc/tor/torrc'
