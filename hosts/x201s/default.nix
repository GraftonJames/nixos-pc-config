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
	# Keep /boot from filling up with old kernels.
	boot.loader.grub.configurationLimit = 10;

	# Compressed swap in RAM, used before any disk swap.
	zramSwap.enable = true;

	# Laptop power saving.
	services.tlp.enable = true;

	# Needed for the Intel 5300 Wi-Fi card.
	hardware.enableRedistributableFirmware = true;

	system.stateVersion = "26.05"; # DO NOT CHANGE
	home-manager.users.james.home.stateVersion = "25.05"; # DO NOT CHANGE
}
