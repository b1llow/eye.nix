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
      in
      {
        formatter = nixfmt-tree;

        devShells = {
          default = pkgs.mkShell {
            inputFrom = [ b.packages.${system}.rizin ];
            packages = with pkgs; [
              uv
            ];
          };
        };
      }
    );
}
