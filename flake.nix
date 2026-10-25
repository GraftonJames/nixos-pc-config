
{
	inputs.nixpkgs.url="github:NixOs/nixpkgs/nixos-25.05";
	inputs.nixpkgs-unstable.url="github:NixOs/nixpkgs/nixos-unstable";
	
	outputs = {nixpkgs, nixpkgs-unstable,...}: 
		let
			system = "x86_64-linux";
			pkgs-unstable = import nixpkgs-unstable {
				inherit system;
				config.allowUnfree=true;
			};
		in {
			nixosConfigurations.x201s = nixpkgs.lib.nixosSystem {
				inherit system;
				specialArgs = {inherit pkgs-unstable; };
				modules=[./configuration.nix];
			};
		};
}
