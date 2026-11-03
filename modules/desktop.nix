{ config, lib, pkgs, repo, ... }:

let
	hostName = config.networking.hostName;

	# `check-updates`: list packages that would change with the newest flake inputs. Script in
	# scripts/check-updates.sh; the result shows in the sway bar (dots/sway/status.sh).
	check-updates = pkgs.writeShellApplication {
		name = "check-updates";
		runtimeInputs = [ pkgs.git pkgs.nvd config.nix.package pkgs.coreutils pkgs.gnugrep ];
		runtimeEnv.REPO = repo;
		text = builtins.readFile ../scripts/check-updates.sh;
	};
in
{
	# Per host, because each check evaluates (and may download) a whole new system: too heavy
	# for the x201s. Without it, `check-updates` can still be run by hand.
	# Colours for sway, foot, fuzzel and swaylock.
	imports = [ ./theme.nix ];

	options.checkUpdates.enable = lib.mkEnableOption "running check-updates every 6 hours for the sway bar";

	config = lib.mkMerge [ {
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
			check-updates
			mako # notifications (exec in the sway config)
			libnotify # notify-send, used by dots/sway/screenshot.sh
			wl-clipboard # wl-copy/wl-paste: screenshots to the clipboard, clipboard history
			cliphist # clipboard history, $mod+c
			jq # dots/sway/screenshot.sh reads swaymsg's JSON
			playerctl # media keys
		];

		# Lets swaylock check the user's password.
		security.pam.services.swaylock = { };

		# Electron apps (Discord) run as native Wayland apps instead of under XWayland. Under
		# XWayland, Discord's screen sharing only sees XWayland windows; on Wayland it uses the
		# screen-sharing portal (xdg-desktop-portal-wlr, enabled by programs.sway).
		environment.sessionVariables.NIXOS_OZONE_WL = "1";

		# Password prompts for apps that ask for admin rights through polkit (gamemode,
		# mounting drives, ...). Without an agent those requests fail silently.
		# graphical-session.target is started with sway (/etc/sway/config.d/nixos.conf).
		systemd.user.services.polkit-gnome-agent = {
			description = "Polkit authentication agent";
			wantedBy = [ "graphical-session.target" ];
			partOf = [ "graphical-session.target" ];
			after = [ "graphical-session.target" ];
			serviceConfig = {
				ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
				Restart = "on-failure";
			};
		};

		# Link ~/.config/sway straight to the repo, so edits apply on reload without a rebuild.
		# ~/.config/sway-host.conf is this machine's file from dots/sway/hosts/, included by the main config.
		home-manager.users.james = { config, ... }: {
			xdg.configFile."sway".source = config.lib.file.mkOutOfStoreSymlink "${repo}/dots/sway";
			xdg.configFile."sway-host.conf".source = config.lib.file.mkOutOfStoreSymlink "${repo}/dots/sway/hosts/${hostName}.conf";
			xdg.configFile."foot".source = config.lib.file.mkOutOfStoreSymlink "${repo}/dots/foot";
			xdg.configFile."fuzzel".source = config.lib.file.mkOutOfStoreSymlink "${repo}/dots/fuzzel";
		};
	}

	# Run check-updates 15 minutes after login, then every 6 hours, at low priority.
	(lib.mkIf config.checkUpdates.enable {
		home-manager.users.james = {
			systemd.user.services.check-updates = {
				Unit.Description = "Check for package updates in the newest flake inputs";
				Service = {
					Type = "oneshot";
					ExecStart = "${check-updates}/bin/check-updates";
					Nice = 19;
					IOSchedulingClass = "idle";
				};
			};
			systemd.user.timers.check-updates = {
				Unit.Description = "Check for package updates every 6 hours";
				Timer = {
					OnStartupSec = "15min";
					OnUnitActiveSec = "6h";
				};
				Install.WantedBy = [ "timers.target" ];
			};
		};
	})
	];
}
