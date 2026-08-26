#!/usr/bin/env bash
#
# check.sh — validate everything in the repo that can be validated.
#
# Every check whose tool is missing is skipped, not failed: a CI runner has no
# compositor to ask, and a machine on the niri profile has no Hyprland. Run it
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
shell_files=(link.sh install.sh check.sh repo.sh scripts/.local/bin/*)
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

# ─── compositors ─────────────────────────────────────────────────────────────
if command -v niri >/dev/null; then
    if niri validate -c niri/.config/niri/config.kdl >/dev/null 2>&1; then
        ok "niri validate"
    else
        bad "niri validate"; niri validate -c niri/.config/niri/config.kdl 2>&1 | tail -5
    fi
else
    skip "niri validate" niri
fi

if command -v Hyprland >/dev/null; then
    out="$(Hyprland --verify-config -c hypr/.config/hypr/hyprland.conf 2>&1)"
    case "$out" in
        *"config ok"*) ok "Hyprland --verify-config" ;;
        *)             bad "Hyprland --verify-config"; printf '%s\n' "$out" | tail -5 ;;
    esac
else
    skip "Hyprland --verify-config" Hyprland
fi

# ─── json ────────────────────────────────────────────────────────────────────
# vscode/ and extras/ are left out on purpose: they are JSON with comments and
# trailing commas (VS Code's own dialect), which jq rejects by design.
if command -v jq >/dev/null; then
    err=0; n=0
    while IFS= read -r f; do
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
    case "$d" in extras) continue ;; esac
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
