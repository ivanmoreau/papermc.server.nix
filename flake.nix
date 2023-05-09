{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ self, nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;
      imports = [
        inputs.flake-parts.flakeModules.easyOverlay
      ];
      perSystem = { pkgs, lib, config, system, self', ... }: {
        packages.papermcserver = pkgs.stdenv.mkDerivation (self: {
          name = "paper";
          version = "1.19.4";
          build = "526";
          plugins = [];
          src = pkgs.fetchurl {
            url = "https://api.papermc.io/v2/projects/paper/versions/${self.version}/builds/${self.build}/downloads/paper-${self.version}-${self.build}.jar";
            sha256 = "sha256-e8bmxAP6X27Ih7Dw35AISo4DPEPtlDat0qsx9cwsDoU=";

          };
          depsBuildBuild = with pkgs; [ makeWrapper ];
          buildInputs = with pkgs; [
            jdk17_headless
          ];
          unpackPhase = "true";
          installPhase = ''
            mkdir -p $out/bin $out/jar
            cp $src $out/jar/paper.jar
            makeWrapper ${pkgs.jdk17_headless}/bin/java $out/bin/paper --add-flags "-jar $out/jar/paper.jar --nogui ${lib.concatStringsSep " " (map (p: "--add-plugin ${p}/jar/plugin.jar") self.plugins)}"
          '';
          meta = with lib; {
            description = "PaperMC Server";
            homepage = "https://papermc.io/";
            license = licenses.gpl3;
            platforms = platforms.all;
          };
        });
        packages.default = self'.packages.papermcserver;

        # You can use an override to add plugins to the server, given that the plugin is
        # available as a nix package. It should be stored in $out/jar/plugin.jar
        # This example adds the plugins to the server:
        packages.test = self'.packages.papermcserver.overrideAttrs (finalAttrs: previousAttrs: {
          plugins = [ ];
        });

        devShells.default = pkgs.mkShell {
            buildInputs = with pkgs; [
              self'.packages.papermcserver
            ];
          };
      };
    };
}
