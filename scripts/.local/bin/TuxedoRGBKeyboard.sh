#!/usr/bin/env bash
#
# TuxedoRGBKeyboard.sh — the keyboard backlight on this TUXEDO: level, on/off,
# and colour.
#
# The LED is one device with two knobs that have nothing to do with each other:
#
#   /sys/class/leds/rgb:kbd_backlight/brightness        the level, 0..255
#   /sys/class/leds/rgb:kbd_backlight/multi_intensity   the colour, "R G B"
#
# Which is why the keyboard could change colour while the brightness keys did
# nothing — those are separate files, and whatever was writing the colour never
# touched the level.
#
# Both files are owned by root. The level is still writable without sudo, but not
# by writing the file: brightnessctl asks systemd-logind, which lets the active
# session set brightness on the backlight and leds subsystems. logind has no such
# method for anything else, so the colour is the one thing here that does need
# root — see `colour` below, which says so rather than failing quietly.
#
# Why a script at all, when this was three keybinds: Hyprland's exec does not run
# a real shell. It splits on ; and || and runs the parts, so `||` works but
# $(...) and `[ ... ]` do not — which is exactly what an on/off toggle is made
# of. Tested, not assumed. The logic has to live somewhere with a real shell,
# and that is here.
#
# Usage:
#   TuxedoRGBKeyboard.sh                 what it is doing now
#   TuxedoRGBKeyboard.sh on | off | toggle
#   TuxedoRGBKeyboard.sh up [step]       default step 10%
#   TuxedoRGBKeyboard.sh down [step]
#   TuxedoRGBKeyboard.sh set 40%         or an absolute 0..255
#   TuxedoRGBKeyboard.sh colour red      or "#ff8800", or "255 136 0"  (needs sudo)

set -uo pipefail

LED=rgb:kbd_backlight
SYS=/sys/class/leds/$LED

RED=$'\e[31m'; DIM=$'\e[2m'; RST=$'\e[0m'
die()  { printf '%s✘ %s%s\n' "$RED" "$*" "$RST" >&2; exit 1; }
note() { printf '%s%s%s\n' "$DIM" "$*" "$RST"; }

[ -d "$SYS" ] || die "no $SYS — is the tuxedo keyboard module loaded? (lsmod | grep tuxedo)"
command -v brightnessctl >/dev/null || die "brightnessctl is not installed"

bctl() { brightnessctl --device="$LED" "$@" >/dev/null; }
level() { brightnessctl --device="$LED" get; }
maxlevel() { brightnessctl --device="$LED" max; }

colour_now() { tr ' ' ',' < "$SYS/multi_intensity"; }

# Named colours, so the common ones do not need hex. The channel order is not
# assumed either — multi_index says which is which, and on this machine it reads
# "red green blue".
name_to_rgb() {
    case "${1,,}" in
        white)   echo "255 255 255" ;;
        red)     echo "255 0 0" ;;
        green)   echo "0 255 0" ;;
        blue)    echo "0 0 255" ;;
        yellow)  echo "255 255 0" ;;
        cyan)    echo "0 255 255" ;;
        magenta|purple) echo "255 0 255" ;;
        orange)  echo "255 100 0" ;;
        pink)    echo "255 60 120" ;;
        \#*)
            local h="${1#\#}"
            [ "${#h}" -eq 6 ] || return 1
            printf '%d %d %d' "0x${h:0:2}" "0x${h:2:2}" "0x${h:4:2}" ;;
        *)       return 1 ;;
    esac
}

case "${1:-status}" in
    status|"")
        printf 'level  : %s / %s  (%s%%)\n' "$(level)" "$(maxlevel)" "$(( $(level) * 100 / $(maxlevel) ))"
        printf 'colour : %s   %s(%s)%s\n' "$(colour_now)" "$DIM" "$(cat "$SYS/multi_index")" "$RST"
        ;;

    on)      bctl -r || bctl set 100% ;;
    off)     bctl -s set 0 ;;

    # -s remembers the level before zeroing it and -r puts that exact level back,
    # so turning it off and on again does not land on some default.
    toggle)
        if [ "$(level)" -gt 0 ]; then bctl -s set 0; else bctl -r || bctl set 50%; fi
        ;;

    up)      bctl set "${2:-10}%+" ;;
    down)    bctl set "${2:-10}%-" ;;

    set)
        [ $# -ge 2 ] || die "set what? e.g. 40% or 128"
        bctl set "$2"
        ;;

    colour|color)
        [ $# -ge 2 ] || die "colour what? a name, #rrggbb, or three numbers"
        if [ $# -eq 4 ]; then rgb="$2 $3 $4"; else rgb="$(name_to_rgb "$2")" || die "unknown colour: $2"; fi

        if [ -w "$SYS/multi_intensity" ]; then
            echo "$rgb" > "$SYS/multi_intensity"
        else
            # logind's SetBrightness covers the level and nothing else, so this
            # is the one operation that genuinely needs root.
            note "colour needs root — multi_intensity is root-owned and logind only hands out brightness"
            sudo sh -c "echo '$rgb' > '$SYS/multi_intensity'" || die "could not write the colour"
        fi
        printf 'colour : %s\n' "$(colour_now)"
        ;;

    -h|--help|help)
        sed -n '3,45p' "$0" | sed 's/^# \{0,1\}//'
        ;;

    *) die "unknown command: $1  (try --help)" ;;
esac
