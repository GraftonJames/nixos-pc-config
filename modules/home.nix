{ config, lib, pkgs, ... }:

{
	home-manager.useGlobalPkgs = true;
	home-manager.useUserPackages = true;
	# Rename existing dotfiles to *.bak instead of refusing to overwrite them.
	home-manager.backupFileExtension = "bak";

	home-manager.users.james = {
		home.stateVersion = "25.05"; # DO NOT CHANGE
	};
}
