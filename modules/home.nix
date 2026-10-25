{ config, lib, pkgs, ... }:

{
	home-manager.useGlobalPkgs = true;
	home-manager.useUserPackages = true;
	# Rename existing dotfiles to *.bak instead of refusing to overwrite them.
	home-manager.backupFileExtension = "bak";

	# home.stateVersion is set per host, like system.stateVersion.
}
