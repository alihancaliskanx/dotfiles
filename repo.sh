#!/usr/bin/env bash
#
# repo.sh — enables the pacman repositories this machine installs from.
#
# install.sh knows which packages to ask for and says nothing about where they
# come from, which works right up until the repository is not enabled. Five of
# its AUR entries are blackarch packages; on a machine without [blackarch] the
# helper falls through to building them from the AUR or simply not finding them,
# and the failure reads as "that package does not exist" rather than "you never
# turned that repo on". The CachyOS v4 repositories are the same story from the
# other side: they are what makes this a CachyOS install rather than an Arch one,
# and nothing in this repo has ever written them down.
#
# So this is the list, in the order pacman reads it, because that order is not
# decoration: the first repository holding a package wins, and the whole point of
# cachyos-v4 is that it shadows core and extra with builds for x86-64-v4. Put
# them underneath and they are dead weight.
#
#   ./repo.sh          add whatever is missing, then refresh
#   ./repo.sh -n       show what it would do, touch nothing
#
# Idempotent: a repository already in pacman.conf is left exactly as it is, so
# this is safe to re-run and safe on a machine that is already set up.

set -uo pipefail

CONF="${PACMAN_CONF:-/etc/pacman.conf}"
DRY=0

RED=$'\e[31m'; GRN=$'\e[32m'; YLW=$'\e[33m'; CYN=$'\e[36m'; DIM=$'\e[2m'; RST=$'\e[0m'
die()  { printf '%s✘ %s%s\n' "$RED" "$*" "$RST" >&2; exit 1; }
warn() { printf '%s! %s%s\n' "$YLW" "$*" "$RST" >&2; }
ok()   { printf '%s✔%s %s\n' "$GRN" "$RST" "$*"; }
dim()  { printf '%s  %s%s\n' "$DIM" "$*" "$RST"; }

usage() { awk 'NR>1 && /^#/ { sub(/^# ?/, ""); print; next } NR>1 { exit }' "${BASH_SOURCE[0]}"; }

while [ "$#" -gt 0 ]; do
    case "$1" in
        -n|--dry-run) DRY=1 ;;
        -h|--help)    usage; exit 0 ;;
        *)            die "unknown option: $1" ;;
    esac
    shift
done

[ -f "$CONF" ] || die "no $CONF"

# ─── the list ────────────────────────────────────────────────────────────────
# name<TAB>mirrorlist, in the order they must appear in pacman.conf.
#
# The three v4 repositories share one mirrorlist and sit above core/extra so
# their builds take precedence. [cachyos] is CachyOS's own packages — the kernel,
# the settings packages — and is generic rather than v4. core/extra/multilib are
# Arch's. blackarch is last because it is the widest and the least trusted of the
# set: anything it also carries should lose to the repository above it.
REPOS=$(cat <<'LIST'
cachyos-v4	/etc/pacman.d/cachyos-v4-mirrorlist
cachyos-core-v4	/etc/pacman.d/cachyos-v4-mirrorlist
cachyos-extra-v4	/etc/pacman.d/cachyos-v4-mirrorlist
cachyos	/etc/pacman.d/cachyos-mirrorlist
core	/etc/pacman.d/mirrorlist
extra	/etc/pacman.d/mirrorlist
multilib	/etc/pacman.d/mirrorlist
blackarch	/etc/pacman.d/blackarch-mirrorlist
LIST
)

# ─── what a repository needs before it can be enabled ────────────────────────
# The Include file comes from a package, and the signatures are checked against a
# keyring that comes from another. Enabling a repo whose mirrorlist is missing
# gives "could not open file" on every pacman run; enabling one whose key is
# missing gives a signature error on the first package from it, which is worse
# because it looks like the package is broken.
need_pkg() {
    pacman -Qq "$1" >/dev/null 2>&1
}

# ─── is this CPU even allowed the v4 repositories? ───────────────────────────
# x86-64-v4 means AVX-512. Enabling those repos on a CPU without it does not
# fail loudly — pacman happily installs binaries the CPU cannot run, and you
# find out when something dies with SIGILL. glibc's own loader is the honest
# answer to "what does this machine support".
supports_v4() {
    /lib/ld-linux-x86-64.so.2 --help 2>/dev/null | grep -q 'x86-64-v4 (supported'
}

# ─── read what is already there ──────────────────────────────────────────────
present() {
    grep -qE "^\[$1\]" "$CONF"
}

printf '%sRepositories%s  (%s)\n\n' "$CYN" "$RST" "$CONF"

missing=""
while IFS=$'\t' read -r name list; do
    [ -n "$name" ] || continue
    if present "$name"; then
        printf '  %s✔%s %-18s %salready enabled%s\n' "$GRN" "$RST" "$name" "$DIM" "$RST"
        continue
    fi
    case "$name" in
        cachyos*-v4)
            if ! supports_v4; then
                printf '  %s-%s %-18s %sskipped — this CPU has no x86-64-v4%s\n' \
                    "$DIM" "$RST" "$name" "$DIM" "$RST"
                continue
            fi
            ;;
    esac
    if [ ! -f "$list" ]; then
        printf '  %s!%s %-18s %smirrorlist missing: %s%s\n' "$YLW" "$RST" "$name" "$DIM" "$list" "$RST"
    fi
    missing="$missing $name"
    printf '  %s+%s %-18s %swill be added%s\n' "$YLW" "$RST" "$name" "$DIM" "$RST"
done <<< "$REPOS"

if [ -z "$missing" ]; then
    printf '\n'
    ok "every repository is already enabled"
    exit 0
fi

# ─── the keyrings ────────────────────────────────────────────────────────────
printf '\n'
for p in cachyos-keyring cachyos-mirrorlist cachyos-v4-mirrorlist; do
    case " $missing " in *cachyos*) ;; *) continue ;; esac
    need_pkg "$p" || warn "not installed: $p  (pacman -S $p)"
done
case " $missing " in
    *blackarch*)
        need_pkg blackarch-mirrorlist || {
            warn "blackarch's mirrorlist and key do not come from a package you already have."
            dim "blackarch publishes strap.sh for it. Fetch it, check it against the"
            dim "sha1 on blackarch.org, and run it — this script will not download and"
            dim "execute a remote installer on your behalf."
        }
        ;;
esac

if [ "$DRY" -eq 1 ]; then
    printf '\n%s(dry-run — nothing was written)%s\n' "$DIM" "$RST"
    exit 0
fi

[ "$(id -u)" -eq 0 ] || die "writing $CONF needs root: sudo ./repo.sh"

# ─── write ───────────────────────────────────────────────────────────────────
# Appended rather than inserted in place. pacman reads top to bottom and the
# order matters, so anything appended after [extra] cannot shadow it — which is
# exactly wrong for the v4 repositories. Rewriting someone's pacman.conf in the
# middle is not something to do from a script, so this refuses instead and says
# where the block belongs.
backup="$CONF.bak.$(date +%Y%m%d-%H%M%S)"
cp -a "$CONF" "$backup" || die "could not back up $CONF"
dim "backup: $backup"

for name in $missing; do
    list=$(awk -F'\t' -v n="$name" '$1==n {print $2}' <<< "$REPOS")
    case "$name" in
        cachyos*)
            if grep -qE '^\[(core|extra)\]' "$CONF"; then
                warn "$name belongs ABOVE [core] and this script only appends."
                dim "add it by hand, immediately under the '# cachyos repos' comment:"
                dim "    [$name]"
                dim "    Include = $list"
                continue
            fi
            ;;
    esac
    printf '\n[%s]\nInclude = %s\n' "$name" "$list" >> "$CONF"
    ok "added [$name]"
done

printf '\n'
dim "refreshing"
pacman -Sy || die "pacman -Sy failed"
ok "done"
