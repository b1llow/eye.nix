{
  description = "billow's nix flake packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
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
        rizin = bpkgs.rizin.override { debug = true; };
        rzpipe' = python3Packages.buildPythonPackage rec {
          pname = "rzpipe";
          version = "unstable";
          src = pkgs.fetchFromGitHub {
            owner = "rizinorg";
            repo = "rz-pipe";
            rev = "master";
            hash = "sha256-qBGwKEATchnS4c3trgOewIs4zjGQGJJhI3tmzSLmEB4=";
          };
          sourceRoot = "${src.name}/python";
          doCheck = false;
          build-system = [ python3Packages.setuptools ];
          pyproject = true;
        };

        m68kPkgs = import nixpkgs {
          inherit system;
          crossSystem = {
            config = "m68k-linux-gnu";
          };
        };
        mipsPkgs = import nixpkgs {
          inherit system;
          crossSystem = {
            config = "mips-linux-gnu";
          };
        };
        llvmPkgs = llvmPackages_20;

      in
      {
        formatter = pkgs.nixfmt-tree.override {
          runtimeInputs = [
            llvmPkgs.clang-tools
            python3Packages.black
          ];
          settings = {
            formatter.c = {
              command = "clang-format";
              options = [ "-i" ];
              includes = [
                "*.c"
                "*.cpp"
                "*.h"
              ];
            };
            formatter.py = {
              command = "black";
              includes = [
                "*.py"
              ];
            };
          };
        };

        devShells =
          let
            shellArgs = {
              hardeningDisable = [ "all" ];
              venvDir = ".nix-venv";

              inputFrom = [
                pkgs.cutter
                pkgs.rizin
              ];
              packages =
                with pkgs;
                [
                  llvmPkgs.clang-tools
                  llvmPkgs.libllvm

                  (pkgs.writeShellScriptBin "clang-format-20" ''
                    exec ${lib.getExe' llvmPackages_20.clang-tools "clang-format"} "$@"
                  '')
                  fish
                  just
                  gdb
                  perf
                  act
                  swig
                  cmake
                  pkg-config
                  meson
                  ninja
                  graphviz
                ]
                ++ (with python3Packages; [
                  venvShellHook
                  # for rizin test
                  pyyaml
                  rzpipe'
                  requests
                  gitpython
                  black

                  # for cutter build
                  shiboken6
                  pyside6

                  # for general use
                  ipython
                  pip
                  # for some xxx
                  pandas
                  beautifulsoup4
                  lxml
                  rpyc
                ])
                ++ lib.optionals (!stdenv.isDarwin) [
                  lldb
                  pkgs.valgrind
                ];

              buildInputs = [
                libclang
                # for rizin build
                pkgs.bzip2
                pkgs.openssl.dev

              ];

              shellHook = ''
                if [ -z "$NIX_DEV_SHELL_FISH" ]; then
                  export NIX_DEV_SHELL_FISH=1
                  export SHELL=${lib.getExe' pkgs.fish "fish"};
                  exec $SHELL
                fi
              '';
            };
          in
          {
            default = pkgs.mkShell.override { stdenv = llvmPackages_20.stdenv; } shellArgs;

            mips = mipsPkgs.mkShell shellArgs;
            m68k = m68kPkgs.mkShell shellArgs;

          };
      }
    );
}
