# NextJS app module for devenv
# React/Next.js web application
{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (config.devenv) root;
  gitRoot =
    if config.git.root != null then
      config.git.root
    else
      lib.replaceStrings [ "/apps/nextjs" ] [ "/" ] root;
in
{
  options.darkmatter.apps.nextjs = {
    enable = lib.mkEnableOption "NextJS app configuration";
  };

  config = lib.mkIf config.darkmatter.apps.nextjs.enable {
    # Enable JavaScript
    darkmatter.javascript.enable = lib.mkDefault true;

    # Additional packages
    packages =
      with pkgs;
      [
        golangci-lint
        delve
        uv
      ]
      ++ lib.optionals pkgs.stdenv.isDarwin [
        apple-sdk_15
      ];

    # Scripts
    scripts.migrate.exec = ''
      ${pkgs.go}/bin/go run . migrate "$@"
    '';

    # Processes
    processes.nextjs-server = {
      exec = ''
        ${pkgs.pnpm}/bin/pnpm dev -F @darkmatter/nextjs
      '';
      cwd = gitRoot;
    };
    processes.storybook = {
      exec = ''
        ${pkgs.pnpm}/bin/pnpm storybook
      '';
      cwd = "${gitRoot}/apps/nextjs";
    };

    # Container
    containers."nextjs" = {
      name = "nextjs";
      version = lib.mkDefault "latest";
      registry = lib.mkDefault "docker://950224716579.dkr.ecr.us-west-2.amazonaws.com/darkmatter/apollo/nextjs";
      startupCommand = pkgs.writeShellScript "start-nextjs" ''
        set -e
        cd /app/apps/nextjs
        exec ${pkgs.nodejs_24}/bin/node server.js
      '';
      copyToRoot = lib.mkIf (!config.container.isBuilding) (
        pkgs.buildEnv {
          name = "nextjs-root";
          paths = [
            (pkgs.writeTextDir "app/.gitkeep" "")
          ];
        }
      );
      defaultCopyArgs = [
        "--dest-creds"
        "x:\"$(flyctl auth token 2>/dev/null || echo 'missing-token')\""
      ];
    };
  };
}
