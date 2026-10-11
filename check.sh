#!/usr/bin/env bash
#
# check.sh — validate everything in the repo that can be validated.
#
# Every check whose tool is missing is skipped, not failed: a CI runner has no
# compositor to ask. Run it
# locally for the full set, CI runs whatever it has.
#
#   ./check.sh

set -uo pipefail

REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO" || exit 1

RED=$'\e[31m'; GRN=$'\e[32m'; YLW=$'\e[33m'; DIM=$'\e[2m'; RST=$'\e[0m'
fail=0

ok()   { printf '%s✔%s %s\n' "$GRN" "$RST" "$*"; }
bad()  { printf '%s✘ %s%s\n' "$RED" "$*" "$RST"; fail=1; }
skip() { printf '%s- %s (%s missing)%s\n' "$DIM" "$1" "$2" "$RST"; }
warn() { printf '%s! %s%s\n' "$YLW" "$*" "$RST"; }

# ─── shell ───────────────────────────────────────────────────────────────────
shell_files=(link.sh install.sh check.sh repo.sh test.sh scripts/.local/bin/*)
err=0
for f in "${shell_files[@]}"; do
    [ -f "$f" ] || continue
    bash -n "$f" 2>/dev/null || { bad "syntax: $f"; err=1; }
done
[ "$err" -eq 0 ] && ok "bash -n  (${#shell_files[@]} scripts)"

if command -v shellcheck >/dev/null; then
    # Warning level and up: the info-level SC2015/SC2086 hits are idiomatic here.
    # SC1090/SC1091: the scripts source files that only exist in $HOME.
    if shellcheck -S warning -e SC1090,SC1091 "${shell_files[@]}" >/tmp/shellcheck.$$ 2>&1; then
        ok "shellcheck"
    else
        bad "shellcheck"; cat /tmp/shellcheck.$$
    fi
    rm -f /tmp/shellcheck.$$
else
    skip "shellcheck" shellcheck
fi

# ─── compositor ──────────────────────────────────────────────────────────────
# The Hyprland config is Lua. Syntax is checked wherever luac is.
lua_files=(hypr/.config/hypr/*.lua)
if command -v luac >/dev/null; then
    err=0
    for f in "${lua_files[@]}"; do
        [ -f "$f" ] || continue
        luac -p "$f" 2>/dev/null || { bad "lua syntax: $f"; err=1; }
    done
    [ "$err" -eq 0 ] && ok "luac -p  (${#lua_files[@]} lua files)"
else
    skip "luac -p" luac
fi

# Loading it needs Omarchy's tree: hyprland.lua starts by running its bootstrap,
# which resolves require("hypr.*") against $HOME/.config. A throwaway HOME whose
# .config/hypr is this repo's makes that the tracked files rather than whatever
# happens to be linked. The XDG variables are dropped with it: Omarchy lists its
# state directory through XDG_STATE_HOME and requires what it finds through
# HOME, and with the two pointing at different homes it finds files it cannot
# then load.
omarchy_root="${OMARCHY_PATH:-/usr/share/omarchy}"
if command -v Hyprland >/dev/null && [ -f "$omarchy_root/default/hypr/bootstrap.lua" ]; then
    tmp_home="$(mktemp -d)"
    mkdir -p "$tmp_home/.config"
    ln -s "$REPO/hypr/.config/hypr" "$tmp_home/.config/hypr"
    out="$(env -u XDG_STATE_HOME -u XDG_CONFIG_HOME HOME="$tmp_home" \
        Hyprland --verify-config -c "$tmp_home/.config/hypr/hyprland.lua" 2>&1)"
    rm -f "$tmp_home/.config/hypr"
    rmdir "$tmp_home/.config" "$tmp_home"
    case "$out" in
        *"config ok"*) ok "Hyprland --verify-config  (lua)" ;;
        *)             bad "Hyprland --verify-config  (lua)"; printf '%s\n' "$out" | tail -5 ;;
    esac
else
    skip "Hyprland --verify-config  (lua)" "Hyprland or Omarchy"
fi

# ─── link.sh ─────────────────────────────────────────────────────────────────
if out="$(./test.sh 2>&1)"; then
    ok "test.sh  ($(printf '%s\n' "$out" | tail -n 1 | sed 's/\x1b\[[0-9;]*m//g; s/^[^0-9]*//'))"
else
    bad "test.sh"; printf '%s\n' "$out" | grep '✘'
fi

# ─── json ────────────────────────────────────────────────────────────────────
# vscode/ and extras/ are left out on purpose: they are JSON with comments and
# trailing commas (VS Code's own dialect), which jq rejects by design.
if command -v jq >/dev/null; then
    err=0; n=0
    while IFS= read -r f; do
        [ -f "$f" ] || continue
        n=$((n + 1))
        jq -e . "$f" >/dev/null 2>&1 || { bad "invalid json: $f"; err=1; }
    done < <(git ls-files '*.json' | grep -vE '^(vscode|extras)/')
    [ "$err" -eq 0 ] && ok "jq  ($n json files)"
else
    skip "json" jq
fi

if command -v stylua >/dev/null; then
    stylua --check nvim/ >/dev/null 2>&1 && ok "stylua --check" || bad "stylua --check (run: stylua nvim/)"
else
    skip "stylua --check" stylua
fi

# ─── repo consistency ────────────────────────────────────────────────────────
# A package directory that no profile mentions is linked by nobody — exactly the
# way a new package gets forgotten after being created.
# link.sh itself is the source of truth; parsing its arrays by hand went wrong
# in three different ways. `profile` prints every profile plus the manual ones.
listed=" $(./link.sh profile 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' | tr -s '[:space:]' ' ') "
orphans=""
for d in */; do
    d="${d%/}"
    case "$d" in extras|fixes|themes|temp) continue ;; esac
    case "$listed" in *" $d "*) ;; *) orphans="$orphans $d" ;; esac
done
if [ -n "$orphans" ]; then
    warn "no profile links these packages:$orphans"
else
    ok "every package belongs to a profile"
fi

echo
[ "$fail" -eq 0 ] && ok "all good" || bad "something failed"
exit "$fail"
