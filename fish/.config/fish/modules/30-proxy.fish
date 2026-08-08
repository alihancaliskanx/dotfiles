# 30-proxy — proxy and Tor.
#
# The functions here are ONLY the ones that change the current shell's environment
# variables; a script cannot do that. Everything that touches persistent
# configuration lives in the shared scripts (shared with zsh):
#
#   net-proxy  git|docker|ssh|sart on|off   →  ~/.local/bin/net-proxy
#   net-tunnel on|off|status|check          →  ~/.local/bin/net-tunnel
#   tor-net    proxy|direct|check|status    →  ~/.local/bin/tor-net
#   tor-control                             →  ControlPort / NEWNYM
#
# The address comes from $PROXY_ADDR in 00-env.fish.

# ── the current shell's env ──────────────────────────────────────────────────
function proxy_on --description 'Turn on the phone HTTP proxy for this shell'
    set -l url "http://$PROXY_ADDR"
    set -gx http_proxy $url
    set -gx https_proxy $url
    set -gx ftp_proxy $url
    set -gx HTTP_PROXY $url
    set -gx HTTPS_PROXY $url
    set -gx no_proxy "localhost,127.0.0.1,::1,.local"
    set -gx NO_PROXY $no_proxy
    echo "✅ Proxy active: $PROXY_ADDR"
end

function proxy_off --description 'Clear this shell\'s proxy env'
    set -e http_proxy https_proxy ftp_proxy all_proxy no_proxy
    set -e HTTP_PROXY HTTPS_PROXY FTP_PROXY ALL_PROXY NO_PROXY
    echo "🚫 Proxy off."
end

function tor_on --description 'Route this shell out through Tor SOCKS5'
    set -l url "socks5h://127.0.0.1:9050"
    set -gx http_proxy $url
    set -gx https_proxy $url
    set -gx ftp_proxy $url
    set -gx all_proxy $url
    set -gx HTTP_PROXY $url
    set -gx HTTPS_PROXY $url
    set -gx FTP_PROXY $url
    set -gx ALL_PROXY $url
    set -gx no_proxy "localhost,127.0.0.1,::1,.local"
    set -gx NO_PROXY $no_proxy
    echo "🧅 Tor proxy active: 127.0.0.1:9050"
end

function tor_off --description 'Clear the Tor proxy env'
    proxy_off
end

function proxy_status --description 'Which proxy is on'
    net-proxy status
end

# ── persistent settings: thin wrappers around the shared scripts ─────────────
# (exactly the same names as in zsh, so muscle memory keeps working)
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

# ── follow net-auto ──────────────────────────────────────────────────────────
# See the zsh module: the state file is written by net-auto.service, and reading
# it keeps a TCP timeout out of shell startup on networks with no proxy.
set -l _na_state (test -n "$XDG_CACHE_HOME"; and echo $XDG_CACHE_HOME; or echo $HOME/.cache)/net-auto/state
if test -r $_na_state; and test (cat $_na_state) = on
    proxy_on >/dev/null
end
