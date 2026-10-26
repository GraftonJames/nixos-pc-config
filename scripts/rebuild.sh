# `rebuild`: pull new commits from the remote (fast-forward only), `nh os switch`,
# then commit and push any local changes if the switch succeeded.
# Packaged in modules/shell.nix, which sets REPO to the checkout path on this machine.

cd "$REPO" || exit 1

has_upstream=false
online=false
if ! git rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
	echo "No upstream branch set, building the local copy."
elif ! git fetch --quiet; then
	has_upstream=true
	echo "Could not reach the remote (offline?), building the local copy."
else
	has_upstream=true
	online=true
	behind=$(git rev-list --count 'HEAD..@{u}')
	ahead=$(git rev-list --count '@{u}..HEAD')
	if [ "$behind" -gt 0 ] && [ "$ahead" -gt 0 ]; then
		echo "Local and remote have diverged ($ahead local, $behind remote commits). Sort it out with git first."
		exit 1
	elif [ "$behind" -gt 0 ]; then
		echo "Pulling $behind new commit(s):"
		git log --oneline 'HEAD..@{u}'
		git pull --ff-only --quiet
	else
		echo "Already up to date with the remote."
	fi
fi

if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
	echo "Uncommitted changes in $PWD will be included in this build:"
	git status --short --untracked-files=no
fi

# Untracked files are never committed automatically (the repo may be public), and
# flakes can't see them, so they aren't part of the build either.
untracked=$(git ls-files --others --exclude-standard)
if [ -n "$untracked" ]; then
	echo "Untracked files, not built or committed (git add them if they belong in the repo):"
	echo "$untracked" | sed 's/^/  /'
fi

# Pass the flake explicitly so this doesn't rely on NH_FLAKE being set in the session.
# set -e (from writeShellApplication) stops here if the build or switch fails.
nh os switch "$REPO" "$@"

# The switch worked: commit changes to tracked files (including flake.lock) and
# anything already staged with git add, then push.
git add --update
if ! git diff --cached --quiet; then
	if ! git commit --quiet --message "rebuild on $HOSTNAME: $(date '+%Y-%m-%d %H:%M')"; then
		echo "Commit failed (is git user.name/user.email set?). Changes are staged but not committed."
		exit 1
	fi
	echo "Committed: $(git log -1 --oneline)"
fi

if ! $has_upstream; then
	echo "No upstream branch set, not pushing."
elif [ "$(git rev-list --count '@{u}..HEAD')" -eq 0 ]; then
	: # Nothing to push.
elif ! $online; then
	echo "Offline, not pushing. Run rebuild or git push again when back online."
elif ! git push --quiet; then
	echo "Push failed. The commit is saved locally; run git push when it can reach the remote."
	exit 1
else
	echo "Pushed to $(git rev-parse --abbrev-ref '@{u}')."
fi
