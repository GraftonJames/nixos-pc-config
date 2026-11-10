{ config, lib, pkgs, ... }:

{
	environment.systemPackages = with pkgs; [
		firefox
		discord
		stremio
		calibre # e-book library and reader
		foot # $term in dots/sway/config; CPU-rendered, no GPU needed
	];
}
