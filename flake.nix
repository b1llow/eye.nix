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
            inputFrom = [
              b.packages.${system}.rizin
              pkgs.cutter
            ];
            packages = [
              meson
              ninja
              just
              llvmPackages_20.clang-tools
            ]
            ++ lib.optionals (!stdenv.isDarwin) [ lldb ];
            venvDir = ".nix-venv";
            nativeBuildInputs = [
              swig
              pkgs.cmake
              pkgs.pkg-config
            ];
            buildInputs = [
              b.packages.${system}.rizin
              libclang

              # for rizin build
              pkgs.bzip2

              # for cutter build
              pkgs.qt6.full
              pkgs.graphviz
            ]
            ++ (with python3Packages; [
              venvShellHook
              # for rizin test
              pyyaml
              rzpipe
              requests
              gitpython

              # for cutter build
              shiboken6
              pyside6

              # for general use
              ipython
            ]);
          };
        };
      }
    );
}
