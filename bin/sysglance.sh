#!/usr/bin/env bash
# sysglance.sh — a system overview at a glance.
#
# A compact, dependency-light system report: host/OS, CPU, memory, GPU,
# storage, network, and power. Reads mostly from /proc and /sys, so it needs
# no root; external tools (lscpu, lspci, sensors, iw) are used when present
# and skipped cleanly when not.
#
#   sysglance.sh          full overview
#   sysglance.sh -h       help
#
# Deps: coreutils/util-linux. Optional: pciutils (lspci), lm_sensors, iw.

set -u

# ---- colours (auto-off when not a tty) ----
if [ -t 1 ]; then
    B=$'\e[1m'; DIM=$'\e[2m'; G=$'\e[32m'; Y=$'\e[33m'; C=$'\e[36m'; R=$'\e[0m'
else B=''; DIM=''; G=''; Y=''; C=''; R=''; fi

case "${1:-}" in -h|--help) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;; esac

have()     { command -v "$1" >/dev/null 2>&1; }
section()  { printf '\n%s%s%s\n' "$B$C" "$1" "$R"; }
# row LABEL VALUE — prints only when VALUE is non-empty
row()      { [ -n "${2:-}" ] && printf '  %s%-11s%s %s\n' "$G" "$1" "$R" "$2"; }
first()    { awk 'NF{print;exit}'; }                 # first non-blank line
gib()      { awk -v k="$1" 'BEGIN{printf "%.1f", k/1048576}'; }  # kB -> GiB

# ---------------------------------------------------------------- host / OS
section "SYSTEM"
row "Host"   "$(uname -n)"
if [ -r /etc/os-release ]; then
    row "OS" "$(. /etc/os-release 2>/dev/null; echo "${PRETTY_NAME:-$NAME}")"
fi
row "Kernel" "$(uname -r)"
row "Arch"   "$(uname -m)"

# uptime + boot time from /proc/uptime
if [ -r /proc/uptime ]; then
    up=$(awk '{print int($1)}' /proc/uptime)
    d=$((up/86400)); h=$(((up%86400)/3600)); m=$(((up%3600)/60))
    u=""; [ "$d" -gt 0 ] && u="${d}d "; u="${u}${h}h ${m}m"
    row "Uptime" "$u"
    have date && row "Booted" "$(date -d "@$(( $(date +%s) - up ))" '+%Y-%m-%d %H:%M')"
fi
have pacman && row "Packages" "$(pacman -Qq 2>/dev/null | wc -l) (pacman)"
row "Shell"  "$(basename "${SHELL:-}")"
# desktop / compositor
de="${XDG_CURRENT_DESKTOP:-}"
[ -z "$de" ] && for w in sway Hyprland river niri labwc weston i3 dwm bspwm; do
    pgrep -x "$w" >/dev/null 2>&1 && { de="$w"; break; }
done
row "Desktop" "$de"
row "Session" "${XDG_SESSION_TYPE:-}"

# ---------------------------------------------------------------- hardware
section "HARDWARE"
vendor=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null)
product=$(cat /sys/class/dmi/id/product_name 2>/dev/null)
row "Model" "$(echo "$vendor $product" | sed 's/^ *//; s/ *$//')"

if have lscpu; then
    cpu=$(lscpu | awk -F': +' '/^Model name/{print $2; exit}')
else
    cpu=$(awk -F': ' '/model name/{print $2; exit}' /proc/cpuinfo 2>/dev/null)
fi
ncpu=$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo 2>/dev/null)
row "CPU" "${cpu:-Unknown}${ncpu:+  ($ncpu threads)}"

# current CPU freq (max across cores), best-effort
if ls /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq >/dev/null 2>&1; then
    mhz=$(awk '{if($1>m)m=$1}END{if(m)printf "%d", m/1000}' \
        /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq 2>/dev/null)
    row "CPU freq" "${mhz:+${mhz} MHz}"
fi
[ -r /proc/loadavg ] && row "Load" "$(awk '{print $1", "$2", "$3}' /proc/loadavg)"

# temperature: prefer lm_sensors, else a thermal zone
temp=""
if have sensors; then
    temp=$(sensors 2>/dev/null | awk -F'[+°]' '/Package id 0:|Tctl:|Tdie:/{print $2"°C"; exit}')
    [ -z "$temp" ] && temp=$(sensors 2>/dev/null | awk -F'[+°]' '/^Core 0:|^temp1:/{print $2"°C"; exit}')
fi
if [ -z "$temp" ] && [ -r /sys/class/thermal/thermal_zone0/temp ]; then
    t=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
    [ -n "$t" ] && temp="$((t/1000))°C"
fi
row "Temp" "$temp"

# GPU(s)
if have lspci; then
    while IFS= read -r line; do
        [ -n "$line" ] && row "GPU" "$line"
    done < <(lspci 2>/dev/null | grep -Ei 'vga|3d|display' | sed -E 's/^[^ ]+ [^:]*: //')
fi

# ---------------------------------------------------------------- memory
section "MEMORY"
if [ -r /proc/meminfo ]; then
    mt=$(awk '/^MemTotal:/{print $2}'     /proc/meminfo)
    ma=$(awk '/^MemAvailable:/{print $2}' /proc/meminfo)
    st=$(awk '/^SwapTotal:/{print $2}'    /proc/meminfo)
    sf=$(awk '/^SwapFree:/{print $2}'     /proc/meminfo)
    if [ -n "${mt:-}" ] && [ -n "${ma:-}" ]; then
        used=$((mt-ma)); pct=$(awk -v u="$used" -v t="$mt" 'BEGIN{printf "%d", u*100/t}')
        row "RAM" "$(gib "$used") / $(gib "$mt") GiB  (${pct}%)"
    fi
    if [ -n "${st:-}" ] && [ "$st" -gt 0 ] 2>/dev/null; then
        su=$((st-sf))
        row "Swap" "$(gib "$su") / $(gib "$st") GiB"
    fi
fi

# ---------------------------------------------------------------- storage
section "STORAGE"
if have df; then
    printf '  %s%-18s %6s %6s %5s  %s%s\n' "$DIM" "MOUNT" "SIZE" "USED" "USE%" "FS" "$R"
    # One row per underlying device: btrfs subvolumes share a device and would
    # otherwise repeat the same usage for /, /home, /swap, etc.
    df -hlP -x tmpfs -x devtmpfs -x efivarfs -x squashfs -x overlay 2>/dev/null \
        | awk 'NR>1{print $6, $2, $3, $5, $1}' | sort | awk '!seen[$5]++' \
        | while read -r mnt size used pct src; do
            printf '  %-18s %6s %6s %5s  %s\n' "$mnt" "$size" "$used" "$pct" "$src"
        done
fi

# ---------------------------------------------------------------- network
section "NETWORK"
if have ip; then
    # default route -> interface, source IP, gateway
    read -r _ _ gw _ dev _ < <(ip route show default 2>/dev/null | first)
    if [ -n "${dev:-}" ]; then
        ip4=$(ip -4 -o addr show "$dev" 2>/dev/null | awk '{print $4}' | paste -sd', ' -)
        row "Interface" "$dev"
        row "IPv4" "$ip4"
        row "Gateway" "${gw:-}"
        # SSID if this is a wireless link
        if have iw; then
            ssid=$(iw dev "$dev" link 2>/dev/null | awk -F': ' '/SSID/{print $2; exit}')
            row "Wi-Fi" "$ssid"
        fi
    else
        row "Status" "no default route"
    fi
fi

# ---------------------------------------------------------------- power
have_bat=false
for bat in /sys/class/power_supply/BAT*; do
    [ -d "$bat" ] || continue
    have_bat=true
    cap=$(cat "$bat/capacity" 2>/dev/null)
    st=$(cat "$bat/status" 2>/dev/null)
    [ "$have_bat" = true ] && [ -z "${_pshown:-}" ] && { section "POWER"; _pshown=1; }
    row "$(basename "$bat")" "${cap:+${cap}%}${st:+  ($st)}"
done
for ac in /sys/class/power_supply/A[CD]* /sys/class/power_supply/ACAD; do
    [ -r "$ac/online" ] || continue
    [ -z "${_pshown:-}" ] && { section "POWER"; _pshown=1; }
    o=$(cat "$ac/online" 2>/dev/null)
    row "$(basename "$ac")" "$([ "$o" = 1 ] && echo Connected || echo Disconnected)"
done

echo
