{ config, lib, pkgs, ... }:

{
	environment.systemPackages = with pkgs; [
		firefox
		discord
		stremio
		foot # $term in dots/sway/config; CPU-rendered, no GPU needed
	];
}
