{ config, lib, pkgs, ... }:

# Imported per host: Steam and gaming tools. Not for the x201s (no AVX, old GPU).
# GPU drivers are hardware-specific and go in the host file.
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
}
