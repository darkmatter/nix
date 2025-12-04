{
  description = "Darkmatter devshell - reusable Nix modules for development environments";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devenv.url = "github:cachix/devenv";
  };

  outputs =
    inputs@{
      flake-parts,
      devenv,
      self,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        devenv.flakeModule
        ./modules/flake-parts
      ];

      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        {
          # Enable agenix-rekey workflow generation for this repo
          darkmatter.ci.agenix-rekey = {
            enable = true;
            cachix.enable = true;
            cachix.name = "darkmatter";
          };

          devenv.shells.default = {
            imports = [ ./devenv.nix ];
          };
        };

      flake = {
        # Flake-parts modules - for use in any flake-parts based flake
        # Usage: imports = [ inputs.darkmatter.flakeModules.default ];
        flakeModules = {
          default = ./modules/flake-parts;
          agenix-rekey = ./modules/flake-parts/ci/agenix-rekey.nix;
        };

        # Devenv modules - for use in devenv.nix files
        # Usage: imports = [ inputs.darkmatter.devenvModules.default ];
        devenvModules = {
          default = ./modules/devenv;
          go = ./modules/devenv/languages/go.nix;
          python = ./modules/devenv/languages/python.nix;
          javascript = ./modules/devenv/languages/javascript.nix;
          git-hooks = ./modules/devenv/git-hooks.nix;
        };
      };
    };
}
