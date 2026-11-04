{ config, lib, pkgs, ... }:

{
	imports = [
		./hardware-configuration.nix
		../../modules/desktop.nix
		../../modules/apps.nix
		../../modules/gaming.nix # Steam (programs.steam), gamemode, gamescope
	];

	# Desktop only: claude-code needs AVX (the x201s lacks it); discord is too heavy for the laptops.
	# pkgs.claude-code comes from the claude-code-nix overlay in flake.nix.
	environment.systemPackages = with pkgs; [
		claude-code
	];

	# Show available package updates in the sway bar (modules/desktop.nix).
	checkUpdates.enable = true;

	# UEFI: systemd-boot on the EFI partition. Secure Boot must be off in the firmware.
	boot.loader.systemd-boot.enable = true;
	boot.loader.efi.canTouchEfiVariables = true;
	# Keep the EFI partition from filling up with old kernels.
	boot.loader.systemd-boot.configurationLimit = 10;

	# 64 GiB disk swapfile (size is in MiB). It already exists; NixOS keeps it while the size matches.
	swapDevices = [
		{ device = "/.swapfile"; size = 64 * 1024; }
	];

	boot.kernelPackages = pkgs.linuxPackages_latest;
	# Firmware for the AMD GPU and other devices, plus CPU microcode updates.
	hardware.enableRedistributableFirmware = true;
	hardware.usb-modeswitch.enable = true;

	# The release this machine was installed with (matches /etc/nixos/configuration.nix);
	# Home Manager's is 25.05 because that's the Home Manager release it started on. Never change them.
	system.stateVersion = "26.05"; # DO NOT CHANGE
	home-manager.users.james.home.stateVersion = "25.05"; # DO NOT CHANGE
}
