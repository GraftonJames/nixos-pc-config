# `check-updates`: build this machine's config against the newest flake inputs and list
# which packages would change, without touching the real flake.lock.
# Packaged in modules/desktop.nix, which sets REPO. Run every 6 hours by a user timer on hosts
# with checkUpdates.enable; writes the result to ~/.cache/check-updates/ for dots/sway/status.sh.

cache="${XDG_CACHE_HOME:-$HOME/.cache}/check-updates"
mkdir -p "$cache"
host=$(cat /proc/sys/kernel/hostname)

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# Copy the checkout (with .git, so the flake sees the same files as the real one:
# tracked files plus uncommitted changes) and update the lock in the copy only.
cp -a "$REPO/." "$tmp/repo"
rm -f "$tmp/repo/result"
nix flake update --flake "$tmp/repo" 2>"$tmp/update.log" || { cat "$tmp/update.log" >&2; exit 1; }

# Always build and compare with the running system, not with the repo's flake.lock: the repo
# may have been pulled or updated without switching. When nothing changed, the build finds
# everything already in the store and only costs the evaluation.
nix build --no-link --print-out-paths \
	"$tmp/repo#nixosConfigurations.$host.config.system.build.toplevel" >"$tmp/out"
# nvd marks changed versions with [U...] (upgrade) or [D...] (downgrade).
nvd diff /run/current-system "$(cat "$tmp/out")" | grep -E '^\[[UD]' >"$tmp/list" || true

count=$(wc -l <"$tmp/list")
mv "$tmp/list" "$cache/list"
# Record which system the count was worked out against, so the bar can drop it after a switch.
echo "$count $(readlink /run/current-system)" >"$cache/status"

if [ "$count" -eq 0 ]; then
	echo "No package updates."
else
	echo "$count package update(s) available (run rebuild after nix flake update):"
	cat "$cache/list"
fi
