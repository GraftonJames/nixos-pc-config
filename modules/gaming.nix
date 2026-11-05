{ config, lib, pkgs, ... }:

# Imported per host: Steam and gaming tools. Not for the x201s (no AVX, old GPU).
# GPU drivers are hardware-specific and go in the host file.
let
	# WoW addon manager. WoW Forever needs 2.24.0 or newer and nixos-25.05 has 2.20.0, so this
	# pins a release directly. It can't update itself from the Nix store: to update, change
	# version and hash. The hash is the sha512 in the release's latest-linux.yml.
	wowup-cf = let
		pname = "wowup-cf";
		version = "2.25.4";
		src = pkgs.fetchurl {
			url = "https://github.com/WowUp/WowUp.CF/releases/download/v${version}/WowUp-CF-${version}.AppImage";
			hash = "sha512-j77hrdC86DHs0jbVWj75JJpwxIcSWmhdU6mFHTesYkxXCJozBNudNA6PN8TDYhi9wdT3IKB8i/xYks5iuVeNXA==";
		};
		contents = pkgs.appimageTools.extractType2 { inherit pname version src; };
	in pkgs.appimageTools.wrapType2 {
		inherit pname version src;
		# Adds it to fuzzel, with its icon.
		extraInstallCommands = ''
			install -m 444 -D ${contents}/${pname}.desktop -t $out/share/applications
			substituteInPlace $out/share/applications/${pname}.desktop \
				--replace-fail 'Exec=AppRun' 'Exec=${pname}'
			cp -r ${contents}/usr/share/icons $out/share
		'';
	};
in
{
	programs.steam = {
		enable = true;
		# Also turns on 32-bit graphics drivers (hardware.graphics.enable32Bit).
		remotePlay.openFirewall = true;
		localNetworkGameTransfers.openFirewall = true;
	};

	# Run a game with `gamemoderun %command%` in its Steam launch options.
	programs.gamemode.enable = true;

	# Wrap a game in its own compositor: `gamescope -- %command%`.
	programs.gamescope.enable = true;

	environment.systemPackages = with pkgs; [
		bolt-launcher 
		lutris
		wowup-cf
	];
}
