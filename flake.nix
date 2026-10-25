{
	inputs.nixpkgs.url="github:NixOs/nixpkgs/nixos-25.05";
	inputs.nixpkgs-unstable.url="github:NixOs/nixpkgs/nixos-unstable";
	inputs.home-manager = {
		url = "github:nix-community/home-manager/release-25.05";
		inputs.nixpkgs.follows = "nixpkgs";
	};

	outputs = {nixpkgs, nixpkgs-unstable, home-manager, ...}:
		let
			system = "x86_64-linux";
			# Where this repo is checked out on the machine.
			repo = "/home/james/repos/nixos-pc-config";
			pkgs-unstable = import nixpkgs-unstable {
				inherit system;
				config.allowUnfree=true;
			};

			# Modules every host gets.
			commonModules = [
				home-manager.nixosModules.home-manager
				./modules/base.nix
				./modules/shell.nix
				./modules/home.nix
			];

			mkHost = hostModule: nixpkgs.lib.nixosSystem {
				inherit system;
				specialArgs = {inherit pkgs-unstable repo; };
				modules = commonModules ++ [ hostModule ];
			};
		in {
			nixosConfigurations.x201s = mkHost ./hosts/x201s;
		};
}
