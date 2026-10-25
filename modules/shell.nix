{ config, lib, pkgs, ... }:

{
	programs.zsh.enable = true;

	environment.systemPackages = with pkgs; [
		vim
		git
		nix-output-monitor
		pciutils
	];
}
