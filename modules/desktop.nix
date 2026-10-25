{ config, lib, pkgs, repo, ... }:

let
	hostName = config.networking.hostName;
in
{
	programs.sway = {
		enable = true;
		wrapperFeatures.gtk = true;
	};

	# Text-mode login screen that starts sway; no X server or GPU needed.
	services.greetd = {
		enable = true;
		settings.default_session.command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --asterisks --remember --cmd sway";
	};
	# tuigreet --remember stores the last username here; the greeter user needs to own it.
	systemd.tmpfiles.rules = [ "d /var/cache/tuigreet 0755 greeter greeter - -" ];

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
		brightnessctl
		swayidle
		swaylock
	];

	# Lets swaylock check the user's password.
	security.pam.services.swaylock = { };

	# Link ~/.config/sway straight to the repo, so edits apply on reload without a rebuild.
	# ~/.config/sway-host.conf is this machine's file from dots/sway/hosts/, included by the main config.
	home-manager.users.james = { config, ... }: {
		xdg.configFile."sway".source = config.lib.file.mkOutOfStoreSymlink "${repo}/dots/sway";
		xdg.configFile."sway-host.conf".source = config.lib.file.mkOutOfStoreSymlink "${repo}/dots/sway/hosts/${hostName}.conf";
	};
}
