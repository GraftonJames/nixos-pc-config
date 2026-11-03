#!/bin/sh
# Sway bar status line. dots/sway/config runs this once a second and shows the one line it prints.
# Each part is optional: anything a machine doesn't have (battery, Nix, pCloud) is left out.
#
# To stay light on the x201s, each run only starts `date` and `wpctl`; everything else is read
# with shell builtins. Slow-changing parts (updates, pCloud, rebuild age, network, disk, sensor
# path) are worked out every 15 seconds and kept in $cache between runs.

runtime="${XDG_RUNTIME_DIR:-/tmp}"
cache="$runtime/sway-status-slow"
cpu_prev="$runtime/sway-status-cpu"

# One `date` for both the clock and the cache age: "<epoch> <weekday> <date> <time>".
read -r now clock <<EOF
$(date '+%s %a %F %H:%M:%S')
EOF

status=""
# Appends one part to the line, with " | " between parts. Empty parts are skipped.
add() {
	[ -n "$1" ] && status="${status:+$status | }$1"
}

# --- Slow parts, refreshed every 15 seconds ---------------------------------------------------

refresh_slow() {
	# Package updates found by check-updates ("<count> <system path>"). Only shown while the
	# running system is the one the count was worked out against, so it clears after a switch.
	updates=""
	if read -r count checked_system 2>/dev/null <"$HOME/.cache/check-updates/status" \
		&& [ "$count" -gt 0 ] && [ "$checked_system" = "$(readlink /run/current-system)" ]; then
		updates="$count new pkgs"
	fi

	# pCloud mount (modules/cloud.nix): warn only when the folder exists but nothing is mounted
	# there, e.g. the rclone-mount:.@pcloud service failed or the token file is missing.
	pcloud=""
	if [ -d "$HOME/clouds/pCloud" ] && ! mountpoint -q "$HOME/clouds/pCloud"; then
		pcloud="pCloud ✗"
	fi

	# Time since this machine last switched to a new NixOS generation (rebuild/nh os switch).
	# The profile symlink is replaced on every switch; it doesn't exist on non-NixOS machines.
	rebuilt=""
	if [ -L /nix/var/nix/profiles/system ]; then
		# Minutes under an hour, hours under a day, then days.
		age=$(( now - $(stat -c %Y /nix/var/nix/profiles/system) ))
		if [ "$age" -lt 3600 ]; then
			rebuilt="upd $((age / 60))m ago"
		elif [ "$age" -lt 86400 ]; then
			rebuilt="upd $((age / 3600))h ago"
		else
			rebuilt="upd $((age / 86400))d ago"
		fi
	fi

	# Network from NetworkManager: the Wi-Fi name, "eth" for a wired connection, or "offline".
	# nmcli -t prints TYPE:STATE:CONNECTION per device; take the first connected Wi-Fi or Ethernet.
	network=$(nmcli -t -f TYPE,STATE,CONNECTION device status 2>/dev/null | awk -F: '
		$2 == "connected" && $1 == "wifi"     { print "wifi " $3; exit }
		$2 == "connected" && $1 == "ethernet" { print "eth"; exit }')
	network="${network:-offline}"

	# CPU temperature sensor: k10temp/zenpower (AMD) or coretemp (Intel), else the first
	# thermal zone. Only the path is cached; the value is read every second.
	temp_file=""
	for hwmon in /sys/class/hwmon/hwmon*; do
		read -r name 2>/dev/null <"$hwmon/name" || continue
		case "$name" in
			k10temp|zenpower|coretemp) temp_file="$hwmon/temp1_input"; break ;;
		esac
	done
	[ -r "$temp_file" ] || temp_file=/sys/class/thermal/thermal_zone0/temp

	# Free space on / (where the Nix store lives).
	disk="/ $(df -h --output=avail / | tail -1 | tr -d ' ') free"

	# One value per line, read back in the same order below.
	printf '%s\n' "$now" "$updates" "$pcloud" "$rebuilt" "$network" "$temp_file" "$disk" >"$cache"
}

# Use the cache if it's under 15 seconds old, else refresh it.
cached_at=0
{ read -r cached_at; read -r updates; read -r pcloud; read -r rebuilt; read -r network; read -r temp_file; read -r disk; } \
	2>/dev/null <"$cache"
if [ $(( now - ${cached_at:-0} )) -ge 15 ] || [ $(( now - ${cached_at:-0} )) -lt 0 ]; then
	refresh_slow
fi

add "$updates"
add "$pcloud"
add "$rebuilt"
add "$network"

# --- Fast parts, every second -----------------------------------------------------------------

# Download speed: bytes received on all interfaces except loopback (and container/VM bridges,
# which would count the same traffic twice) since the last run. The previous reading is kept in
# a file. /proc/uptime gives the time in hundredths of a second, so a run that comes a little
# late still divides by the right interval.
net_prev="$runtime/sway-status-net"
read -r uptime _ </proc/uptime
uptime_cs="${uptime%.*}${uptime#*.}"
rx_total=0
# Lines look like "wlp7s0: <rx bytes> <rx packets> ..."; the 2 header lines have no number there.
while IFS=: read -r iface counters; do
	iface="${iface##* }"
	case "$iface" in
		lo|veth*|docker*|br-*|virbr*) continue ;;
	esac
	# shellcheck disable=SC2086 # split the counters into fields on purpose
	set -- $counters
	case "$1" in
		''|*[!0-9]*) continue ;;
	esac
	rx_total=$((rx_total + $1))
done </proc/net/dev
if read -r prev_rx prev_cs 2>/dev/null <"$net_prev" \
	&& [ "$uptime_cs" -gt "$prev_cs" ] && [ "$rx_total" -ge "$prev_rx" ]; then
	rate=$(( (rx_total - prev_rx) * 100 / (uptime_cs - prev_cs) ))
	if [ "$rate" -ge 1048576 ]; then
		rate_tenths=$(( rate * 10 / 1048576 ))
		add "↓ $((rate_tenths / 10)).$((rate_tenths % 10))M/s"
	elif [ "$rate" -ge 1024 ]; then
		add "↓ $((rate / 1024))K/s"
	else
		add "↓ ${rate}B/s"
	fi
fi
echo "$rx_total $uptime_cs" >"$net_prev"

# CPU use since the last run. /proc/stat's first line holds total CPU time per state; idle is
# fields 4 and 5 (idle + iowait). The previous reading is kept in a file because each run is a
# new process, so the first run after login shows "?".
read -r _ user nice system idle iowait irq softirq steal _ </proc/stat
cpu_total=$((user + nice + system + idle + iowait + irq + softirq + steal))
cpu_idle=$((idle + iowait))
cpu="?"
if read -r prev_total prev_idle 2>/dev/null <"$cpu_prev" && [ "$cpu_total" -gt "$prev_total" ]; then
	cpu=$(( 100 * ( (cpu_total - prev_total) - (cpu_idle - prev_idle) ) / (cpu_total - prev_total) ))
fi
echo "$cpu_total $cpu_idle" >"$cpu_prev"

# CPU temperature, in millidegrees in the file.
if [ -n "$temp_file" ] && read -r temp 2>/dev/null <"$temp_file"; then
	add "CPU $cpu% $((temp / 1000))°C"
else
	add "CPU $cpu%"
fi

# RAM in use: total minus what the kernel says is available (free plus reclaimable cache).
# /proc/meminfo is in KiB; shown as used/total GiB with one decimal for used.
while read -r key value _; do
	case "$key" in
		MemTotal:) mem_total=$value ;;
		MemAvailable:) mem_avail=$value; break ;;
	esac
done </proc/meminfo
mem_used_tenths=$(( (mem_total - mem_avail) * 10 / 1048576 ))
add "RAM $((mem_used_tenths / 10)).$((mem_used_tenths % 10))/$(( (mem_total + 524288) / 1048576 ))G"

add "$disk"

# Volume of the default output: wpctl prints "Volume: 0.65", plus " [MUTED]" when muted.
# Read every second so the volume keys show up straight away.
read -r _ volume muted <<EOF
$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
EOF
if [ "$muted" = "[MUTED]" ]; then
	add "VOL mute"
elif [ -n "$volume" ]; then
	# "0.65" -> "65", "1.00" -> "100" (wpctl always prints two decimals).
	# The leading 0 of "05" is stripped so sh doesn't read it as octal.
	volume_frac="${volume#*.}"
	volume_pct=$(( ${volume%.*} * 100 + ${volume_frac#0} ))
	add "VOL $volume_pct%"
fi

# Battery: charge, then "+" while charging or the time left (h:mm) while discharging.
# Takes the first BAT* (usually BAT0; some laptops only have BAT1). Skipped without a battery.
for bat in /sys/class/power_supply/BAT*; do
	read -r capacity 2>/dev/null <"$bat/capacity" || continue
	read -r bat_status 2>/dev/null <"$bat/status"
	battery="BAT $capacity%"
	case "$bat_status" in
		Charging) battery="$battery +" ;;
		Discharging)
			# Remaining energy / current draw = hours left. Batteries report either
			# energy (µWh, µW) or charge (µAh, µA); the ratio is the same.
			charge_now="" rate=""
			read -r charge_now 2>/dev/null <"$bat/energy_now" || read -r charge_now 2>/dev/null <"$bat/charge_now"
			read -r rate 2>/dev/null <"$bat/power_now" || read -r rate 2>/dev/null <"$bat/current_now"
			if [ -n "$charge_now" ] && [ "${rate:-0}" -gt 0 ]; then
				minutes=$(( charge_now * 60 / rate ))
				battery="$battery $((minutes / 60)):$(printf '%02d' $((minutes % 60)))"
			fi
			;;
	esac
	add "$battery"
	break
done

# The abbreviated weekday, ISO date and time, e.g. "Sat 2018-10-06 14:01:05".
add "$clock"

echo "$status"
