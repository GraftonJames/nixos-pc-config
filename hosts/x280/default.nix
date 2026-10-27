{ config, lib, pkgs, ... }:

{
	imports = [
		# Not in the repo yet: copy /etc/nixos/hardware-configuration.nix from the laptop.
		./hardware-configuration.nix
		../../modules/desktop.nix
		../../modules/apps.nix
	];

	# UEFI: systemd-boot on the EFI partition. Secure Boot must be off in the firmware.
	boot.loader.systemd-boot.enable = true;
	boot.loader.efi.canTouchEfiVariables = true;
	# Keep the EFI partition from filling up with old kernels.
	boot.loader.systemd-boot.configurationLimit = 10;

	# Compressed swap in RAM, used before any disk swap.
	zramSwap.enable = true;

	# Laptop power saving.
	services.tlp.enable = true;

	# Firmware for the Intel Wi-Fi card, plus CPU microcode updates.
	hardware.enableRedistributableFirmware = true;

	# Hardware video decoding on the Intel UHD 620 (firefox, mpv).
	hardware.graphics.extraPackages = [ pkgs.intel-media-driver ];

	# ThinkPad firmware updates from LVFS: `fwupdmgr refresh && fwupdmgr update`.
	services.fwupd.enable = true;

	# Set both to the release the laptop was installed with (see /etc/nixos/configuration.nix),
	# then never change them.
	system.stateVersion = "26.05"; # DO NOT CHANGE
	home-manager.users.james.home.stateVersion = "25.05"; # DO NOT CHANGE
}
