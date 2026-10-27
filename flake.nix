{
	inputs.nixpkgs.url="github:NixOs/nixpkgs/nixos-25.05";
	inputs.home-manager = {
		url = "github:nix-community/home-manager/release-25.05";
		inputs.nixpkgs.follows = "nixpkgs";
	};

	outputs = {nixpkgs, home-manager, ...}:
		let
			# Modules every host gets.
			commonModules = [
				home-manager.nixosModules.home-manager
				./modules/base.nix
				./modules/shell.nix
				./modules/home.nix
				./modules/cloud.nix
			];

			# name: hostname, flake attribute and folder under hosts/.
			# repo: where this repo is checked out on that machine.
			mkHost = { name, repo ? "/home/james/nixos-config", system ? "x86_64-linux" }:
				nixpkgs.lib.nixosSystem {
					inherit system;
					specialArgs = {inherit repo; };
					modules = commonModules ++ [
						(./hosts + "/${name}")
						{ networking.hostName = name; }
					];
				};
		in {
			nixosConfigurations = {
				x201s = mkHost { name = "x201s"; };
				x280 = mkHost { name = "x280"; };
			};
		};
}
