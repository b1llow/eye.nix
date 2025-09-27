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
        inherit (pkgs) lib nixfmt-tree makeWrapper;

        rizin = (b.packages.${system}.rizin).overrideAttrs (old: {
          src = lib.cleanSourceWith {
            src = ./rizin;
            filter =
              path: type:
              let
                bn = baseNameOf path;
              in
              (lib.cleanSourceFilter path type) && !(bn == "flake.nix" || bn == "flake.lock");
          };
          nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
            pkgs.makeWrapper
          ];
          postInstall = (old.postInstall or "") + ''
            wrapProgram $out/bin/rz-test \
              --set PATH $out/bin/
            wrapProgram $out/bin/rz-asm \
              --set PATH $out/bin/
          '';
        });

      in
      {
        packages = {
          inherit rizin;
          default = rizin;
        };

        apps =
          let
            xs = [
              "rz-asm"
              "rz-test"
            ];
          in
          (builtins.listToAttrs (
            map (x: {
              name = x;
              value = {
                type = "app";
                program = "${rizin}/bin/${x}";
              };
            }) xs
          ));

        formatter = nixfmt-tree;

        devShells = {
          default = pkgs.mkShell {
            inputFrom = [ rizin ];
            packages = with pkgs; [
              uv
            ];
          };
        };
      }
    );
}
