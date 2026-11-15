# `sync-extra`: two-way sync of all of pCloud with /mnt/extra/pCloud (rclone bisync).
# Packaged in hosts/desktop/default.nix, which runs it daily from a user timer.
# Extra arguments go to rclone, e.g. `sync-extra --dry-run`.

drive=/mnt/extra
dest="$drive/pCloud"
# Bisync's saved file listings for this pair only, so other bisync jobs can't clash with it.
workdir="${XDG_CACHE_HOME:-$HOME/.cache}/rclone/bisync-extra"

# If the drive failed to mount, the folder would look empty and bisync would treat every
# file as deleted locally. Stop instead.
if ! mountpoint -q "$drive"; then
	echo "sync-extra: $drive is not mounted, skipping." >&2
	exit 1
fi

args=(
	pcloud: "$dest"
	--workdir "$workdir"
	--create-empty-src-dirs
	# Carry on after small errors and recover from an interrupted run, instead of
	# demanding a manual --resync.
	--resilient
	--recover
	--max-lock 2h
	# A file changed on both sides: keep the newer one, rename the other with a .conflict suffix.
	--conflict-resolve newer
	--verbose
)

# The first run has no saved listings, so it needs --resync: it copies files missing on
# each side to the other and deletes nothing. Later runs also sync deletions.
# Bisync's safety check (--max-delete, default 50%) still aborts if too much would be deleted.
if ! compgen -G "$workdir/*.path1.lst" > /dev/null; then
	echo "sync-extra: first run, doing a --resync."
	args+=(--resync)
fi

exec rclone bisync "${args[@]}" "$@"
