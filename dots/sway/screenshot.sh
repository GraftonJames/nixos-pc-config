#!/bin/sh
# Screenshots for the sway bindings in dots/sway/config.
#   screenshot.sh area     select an area with the mouse (Esc cancels)
#   screenshot.sh screen   the monitor that has focus
#   screenshot.sh window   the focused window
# Saves to ~/Pictures/Screenshots/<date>.png, copies the image to the clipboard
# and shows a notification. Needs grim, slurp, jq, wl-copy and notify-send (modules/desktop.nix).

dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"
file="$dir/$(date '+%Y-%m-%d_%H-%M-%S').png"

case "$1" in
	area)
		# slurp exits non-zero when cancelled: take no screenshot then.
		geometry=$(slurp) || exit 0
		grim -g "$geometry" "$file"
		;;
	screen)
		output=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name')
		grim -o "$output" "$file"
		;;
	window)
		geometry=$(swaymsg -t get_tree | jq -r '.. | select(.focused? == true) | .rect | "\(.x),\(.y) \(.width)x\(.height)"')
		grim -g "$geometry" "$file"
		;;
	*)
		echo "usage: $0 area|screen|window" >&2
		exit 1
		;;
esac || exit 1

wl-copy --type image/png <"$file"
notify-send --app-name=screenshot --icon="$file" "Screenshot saved" "${file#"$HOME"/} (also copied)"
