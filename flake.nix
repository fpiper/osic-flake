{
	description = "Open source IC design tools for Sky130";

	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

		open_pdks = {
			url = "github:fpiper/open_pdks-flake";
			inputs.nixpkgs.follows = "nixpkgs";
		};
	};

	outputs = { self, nixpkgs, open_pdks }:
		let
			pkgs = import nixpkgs {
				system = "x86_64-linux";
			};
		in {
			devShells.x86_64-linux.default = self.devShells.x86_64-linux.osic;

			devShells.x86_64-linux.osic = pkgs.mkShell {
				shellHook = ''
				export PS1="osic $ "
				export PDK_ROOT="${open_pdks.outputs.packages.x86_64-linux.open_pdks}/pdk"
				'';
				packages = [
					pkgs.ngspice
					pkgs.magic-vlsi
					pkgs.xschem
				];
			};
		};
}
