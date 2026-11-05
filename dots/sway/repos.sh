#!/bin/sh
# Pick a project in ~/repos with fuzzel and open it in neovim, in a new foot window
# started from the project folder. Bound to $mod+o in dots/sway/config.

repos="$HOME/repos"

if [ ! -d "$repos" ]; then
	notify-send --app-name=repos "No projects folder" "~/repos does not exist"
	exit 1
fi

# fuzzel exits non-zero when cancelled: open nothing then.
project=$(find -L "$repos" -mindepth 1 -maxdepth 1 -type d -not -name '.*' -printf '%f\n' \
	| sort -f \
	| fuzzel --dmenu --prompt 'repo> ') || exit 0

# Enter on text that matches nothing returns that text, or nothing at all, so check the folder exists.
[ -n "$project" ] && [ -d "$repos/$project" ] || exit 0

exec foot --working-directory="$repos/$project" nvim .
