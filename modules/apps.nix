{ config, lib, pkgs, ... }:

{
	environment.systemPackages = with pkgs; [
		firefox
		foot # $term in dots/sway/config; CPU-rendered, no GPU needed
	];
}
