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
        bpkgs = b.packages.${system};

        rizin081 = (
          (bpkgs.rizin.override {
            debug = true;
            rev = "v0.8.1";
            sha256 = "sha256-JuaU5Xil4ttLWuZoWkCHYmMsigSuc+kRqSRcgg5tXqA=";
            mesonDepsSha256 = "sha256-CbQn3B2IWK2o3pQEOtkONcA7775YJ6ZnLQ9T3h94cIM=";
          })
        );
        rizin = bpkgs.rizin.override { debug = true; };
      in
      {
        formatter = nixfmt-tree;

        packages = {
          inherit rizin;
        };

        devShells = {
          default = pkgs.mkShell {
            hardeningDisable = [ "format" ];
            inputFrom = [
              b.packages.${system}.rizin
              pkgs.cutter
            ];
            packages = [
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
              rizin

              libclang
              meson
              ninja

              # for rizin build
              pkgs.bzip2
              pkgs.openssl.dev

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
              pip
            ]);
          };
        };
      }
    );
}
