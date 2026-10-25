
	{ config, lib, pkgs, pkgs-unstable,... }:

	{
	imports =
	[ # Include the results of the hardware scan.
	./hardware-configuration.nix
	];

	# Use the GRUB 2 boot loader.
	boot.loader.grub.enable = true;
	boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only

	networking.hostName = "x201s"; # Define your hostname.

	# NETWORKING
	hardware.enableRedistributableFirmware = true;
	networking.networkmanager.enable = true;

	programs.zsh.enable = true;
	time.timeZone = "Europe/London";

	users.users.james = {
		isNormalUser = true;
		description = "james";
		extraGroups = [ "wheel" ];
		shell = pkgs.zsh;
		home = "/home/james";
		
	};

	nix.settings.experimental-features = [ "nix-command" "flakes" ];

	services.xserver.xkb.layout = "uk";
	services.xserver.xkb.options = "eurosign:e,caps:escape";

	services.pipewire = {
		enable = true;
		pulse.enable = true;
	};

	programs.sway={
		enable=true;
		wrapperFeatures.gtk=true;
	};

	nixpkgs.config.allowUnfree=true;
	environment.systemPackages = with pkgs; [
		firefox
		vim
		nix-output-monitor
		git
		pciutils
	];

  system.stateVersion = "26.05"; # DO NOT CHANGE

}

