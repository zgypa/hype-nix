{
  description = "Hype Markdown presentations packaged for Nix and NixOS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      overlay = final: prev: {
        hype = final.qt6.callPackage ./package.nix { };
      };
      pkgsFor = system: import nixpkgs {
        inherit system;
        overlays = [ overlay ];
      };
    in
    {
      overlays.default = overlay;

      packages = forAllSystems (system:
        let pkgs = pkgsFor system;
        in {
          inherit (pkgs) hype;
          default = pkgs.hype;
        });

      apps = forAllSystems (system:
        let app = {
          type = "app";
          program = "${self.packages.${system}.hype}/bin/hype";
          meta.description = "Hype Markdown presentation editor and CLI";
        };
        in { hype = app; default = app; });

      checks = forAllSystems (system: {
        hype = self.packages.${system}.hype;
      });
    };
}
