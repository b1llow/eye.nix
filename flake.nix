{
  description = "billow's nix flake packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
#    nixpkgs2505.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
    b = {
      url = "github:b1llow/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      b,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        inherit (pkgs)
          lib
          stdenv
          nixfmt-tree
          swig
          libclang
          lldb
          meson
          ninja
          just
          python3Packages
	  llvmPackages_20
          ;
      in
      {
        formatter = nixfmt-tree;

        devShells = {
          default = pkgs.mkShell {
            hardeningDisable = [ "format" ];
            inputFrom = [ b.packages.${system}.rizin ];
            packages = [
              meson
              ninja
              just
              llvmPackages_20.clang-tools
            ]
            ++ lib.optionals (!stdenv.isDarwin) [ lldb ];
            venvDir = ".nix-venv";
            nativeBuildInputs = [ swig ];
            buildInputs = [
              b.packages.${system}.rizin
              libclang
              pkgs.bzip2
            ]
            ++ (with python3Packages; [
              venvShellHook
              pyyaml
              rzpipe
              requests
              gitpython
              ipython
            ]);
          };
        };
      }
    );
}
