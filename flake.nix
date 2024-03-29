{
	description = "Open source IC design tools for Sky130";

	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

		open_pdks = {
			url = "github:fpiper/open_pdks-flake";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		netgen = {
			url = "git://opencircuitdesign.com/netgen";
			flake = false;
		};
		cicsim = {
			url = "github:wulffern/cicsim";
			flake = false;
		};
	};

	outputs = { self, nixpkgs, open_pdks, netgen, cicsim }:
		let
			pkgs = import nixpkgs {
				system = "x86_64-linux";
			};
		in {
			packages.x86_64-linux.netgen =
				let pkgs = import nixpkgs {
							system = "x86_64-linux";
						};
				in pkgs.stdenv.mkDerivation rec {
					name = "netgen";
					src = netgen;
					buildInputs = [ pkgs.tk pkgs.tcl pkgs.python3 ];
					configureFlags = [
						"--with-tcl=${pkgs.tcl}"
						"--with-tk=${pkgs.tk}"
					];
					enableParallelBuildung = true;
				};
			packages.x86_64-linux.cicsim =
				let pkgs = import nixpkgs {
							system = "x86_64-linux";
						};
				in pkgs.python3.pkgs.buildPythonPackage rec {
					name = "cicsim";
					format = "setuptools";
					src = cicsim;
					doCheck = false;

					propagatedBuildInputs = with pkgs.python311Packages; [
						pandas
						tabulate
						click
						matplotlib
						numpy
						pyyaml
						jinja2
					];
					buildInputs = with pkgs.python311Packages; [
						pip
						wheel
						setuptools
						# tikzplotlib # broken with matplotlib 3.8
					];
				};

			devShells.x86_64-linux.default = self.devShells.x86_64-linux.osic;

			devShells.x86_64-linux.osic = let
				finalPython = pkgs.python3.override {
					packageOverrides = python-self: python-super: {
						cicsim = self.packages.x86_64-linux.cicsim;
					};
				};
			in pkgs.mkShell {
				shellHook = ''
				export PS1="osic $ "
				export PDK_ROOT="${open_pdks.outputs.packages.x86_64-linux.open_pdks}/pdk"
				'';
				packages = [
					self.packages.x86_64-linux.netgen
					pkgs.ngspice
					pkgs.magic-vlsi
					pkgs.xschem
					(finalPython.withPackages (ps: [
						ps.cicsim
					]))
					pkgs.pandoc
				];
			};
		};
}
