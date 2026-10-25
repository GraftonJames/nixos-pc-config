{ config, lib, pkgs, ... }:

{
	imports = [
		./hardware-configuration.nix
		../../modules/desktop.nix
		../../modules/apps.nix
	];

	# Legacy BIOS: GRUB on the MBR.
	boot.loader.grub.enable = true;
	boot.loader.grub.device = "/dev/sda";

	networking.hostName = "x201s";

	# Needed for the Intel 5300 Wi-Fi card.
	hardware.enableRedistributableFirmware = true;
	networking.networkmanager.enable = true;

	system.stateVersion = "26.05"; # DO NOT CHANGE
}
