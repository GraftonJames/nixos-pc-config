{ config, lib, pkgs, ... }:

{
	programs.sway = {
		enable = true;
		wrapperFeatures.gtk = true;
	};

	services.pipewire = {
		enable = true;
		pulse.enable = true;
	};

	environment.systemPackages = with pkgs; [
		firefox
	];
}
