{
  description = "Darkmatter devshell - reusable Nix modules for development environments";

  inputs = {
    agenix.url = "github:ryantm/agenix";
    darkmatter-agents.url = "git+ssh://git@github.com/darkmatter/agents";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs@{
      agenix,
      darkmatter-agents,
      flake-parts,
      self,
      ...
    }:
    let
      agentsHomeManagerModule = import ./modules/home-manager/agents.nix { inherit darkmatter-agents; };
      darwinSecretsModule = import ./modules/darwin/secrets.nix { inherit agenix; };
      nixosSecretsModule = import ./modules/nixos/secrets.nix { inherit agenix; };
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      debug = true;
      imports = [
        ./modules/flake-parts
      ];
      flake = {
        # Flake-parts modules - for use in any flake-parts based flake
        # Usage: imports = [ inputs.darkmatter.flakeModules.default ];
        flakeModules = {
          default = ./modules/flake-parts;
          agenix-rekey = ./modules/flake-parts/ci/agenix-rekey.nix;
        };
        homeManagerModules = {
          default = agentsHomeManagerModule;
          agents = agentsHomeManagerModule;
        };
        nixosModules = {
          default = nixosSecretsModule;
          secrets = nixosSecretsModule;
        };
        darwinModules = {
          default = darwinSecretsModule;
          secrets = darwinSecretsModule;
        };
      };

      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      perSystem =
        {
          config,
          pkgs,
          ...
        }:
        {

          devShells.default = pkgs.mkShell {

          };
          # Enable agenix-rekey workflow generation for this repo
          darkmatter.ci.agenix-rekey = {
            enable = true;
            cachix.enable = true;
            cachix.name = "darkmatter";
          };
        };
    };
}
