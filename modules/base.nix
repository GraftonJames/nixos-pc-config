{ config, lib, pkgs, ... }:

{
	nix.settings.experimental-features = [ "nix-command" "flakes" ];
	nixpkgs.config.allowUnfree = true;
	# Hard-link identical files in the Nix store to save disk space.
	nix.optimise.automatic = true;

	networking.networkmanager.enable = true;

	time.timeZone = "Europe/London";
	i18n.defaultLocale = "en_GB.UTF-8";
	services.xserver.xkb.layout = "uk";
	services.xserver.xkb.options = "eurosign:e,caps:escape";
	# Use the same UK layout on the console and the tuigreet login screen.
	console.useXkbConfig = true;

	users.users.james = {
		isNormalUser = true;
		description = "james";
		extraGroups = [ "wheel" "video" ]; # video: backlight control with brightnessctl
		shell = pkgs.zsh;
		home = "/home/james";
	};
}
