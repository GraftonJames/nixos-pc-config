{ config, lib, pkgs, ... }:

{
	nix.settings.experimental-features = [ "nix-command" "flakes" ];
	nixpkgs.config.allowUnfree = true;

	time.timeZone = "Europe/London";
	services.xserver.xkb.layout = "uk";
	services.xserver.xkb.options = "eurosign:e,caps:escape";

	users.users.james = {
		isNormalUser = true;
		description = "james";
		extraGroups = [ "wheel" ];
		shell = pkgs.zsh;
		home = "/home/james";
	};
}
