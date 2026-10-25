{ config, lib, pkgs, ... }:

let
	# Where this repo is checked out on the machine.
	repo = "/home/james/repos/nixos-pc-config";
in
{
	programs.sway = {
		enable = true;
		wrapperFeatures.gtk = true;
	};

	services.pipewire = {
		enable = true;
		pulse.enable = true;
	};

	# Tools dots/sway/config calls
	environment.systemPackages = with pkgs; [
		fuzzel
		grim
		slurp
		gammastep
		pulseaudio # for pactl
		pavucontrol
	];

	# Link ~/.config/sway straight to the repo, so edits apply on reload without a rebuild.
	home-manager.users.james = { config, ... }: {
		xdg.configFile."sway".source = config.lib.file.mkOutOfStoreSymlink "${repo}/dots/sway";
	};
}
