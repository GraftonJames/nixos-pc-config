{ config, lib, pkgs, repo, ... }:

let
	# `rebuild`: pull new commits from the remote (fast-forward only), then `nh os switch`.
	rebuild = pkgs.writeShellApplication {
		name = "rebuild";
		runtimeInputs = [ pkgs.git config.programs.nh.package ];
		text = ''
			cd "${repo}" || exit 1

			if ! git rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
				echo "No upstream branch set, building the local copy."
			elif ! git fetch --quiet; then
				echo "Could not reach the remote (offline?), building the local copy."
			else
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

			if [ -n "$(git status --porcelain)" ]; then
				echo "Warning: uncommitted changes in $PWD will be included in this build."
			fi

			# Pass the flake explicitly so this doesn't rely on NH_FLAKE being set in the session.
			exec nh os switch "${repo}" "$@"
		'';
	};
in
{
	programs.zsh.enable = true;

	# Rebuild with `nh os switch` from anywhere.
	programs.nh = {
		enable = true;
		flake = repo;
		# Weekly cleanup of old generations; keeps the last 3 and anything from the past 14 days.
		clean = {
			enable = true;
			dates = "weekly";
			extraArgs = "--keep-since 14d --keep 3";
		};
	};

	environment.systemPackages = with pkgs; [
		vim
		git
		nix-output-monitor
		pciutils
		rebuild
	];
}
