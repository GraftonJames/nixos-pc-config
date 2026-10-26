{ config, lib, pkgs, repo, ... }:

let
	# `rebuild`: pull, `nh os switch`, then commit and push local changes. Script in scripts/rebuild.sh.
	rebuild = pkgs.writeShellApplication {
		name = "rebuild";
		runtimeInputs = [ pkgs.git config.programs.nh.package ];
		runtimeEnv.REPO = repo;
		text = builtins.readFile ../scripts/rebuild.sh;
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

	# Git identity for commits made on the NixOS machines (e.g. by `rebuild`). Written to /etc/gitconfig.
	programs.git = {
		enable = true;
		config.user = {
			name = "James Grafton";
			email = "jgrafton@posteo.net";
		};
	};

	# Link ~/.vimrc straight to the repo, so edits apply without a rebuild.
	home-manager.users.james = { config, ... }: {
		home.file.".vimrc".source = config.lib.file.mkOutOfStoreSymlink "${repo}/dots/vim/vimrc";
	};

	# ssh-agent per login; the first ssh/git use asks for the key passphrase, later ones reuse it.
	programs.ssh.startAgent = true;
	programs.ssh.extraConfig = ''
		AddKeysToAgent yes
	'';

	environment.systemPackages = with pkgs; [
		vim
		nix-output-monitor
		rsync
		pciutils
		rebuild
	];
}
