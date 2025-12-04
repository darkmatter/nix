# Python language module for devenv
# Provides Python tooling with uv package manager
{
  pkgs,
  lib,
  config,
  ...
}: {
  options.darkmatter.python = {
    enable = lib.mkEnableOption "Python language support";
    version = lib.mkOption {
      type = lib.types.str;
      default = "3.12";
      description = "Python version to use";
    };
    withPostgres = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Include PostgreSQL headers for psycopg2 builds";
    };
  };

  config = lib.mkIf config.darkmatter.python.enable {
    # Environment variables
    # - UV_PROJECT_ENVIRONMENT is cleared so uv uses project-local .venv directories
    # - PostgreSQL config is added when withPostgres is enabled
    env =
      {
        # Override UV_PROJECT_ENVIRONMENT to empty so uv uses project-local .venv
        # This is necessary because languages.python.uv.enable sets it to ${DEVENV_STATE}/venv
        UV_PROJECT_ENVIRONMENT = lib.mkForce "";
      }
      // lib.optionalAttrs config.darkmatter.python.withPostgres {
        PG_CONFIG = "${pkgs.postgresql}/bin/pg_config";
        PSYCOPG2_PG_CONFIG = "${pkgs.postgresql}/bin/pg_config";
      };

    # Python language configuration
    # Note: We disable the built-in venv/sync since we have multiple Python
    # directories (apps/nn, apps/apollo, packages/proto). Each app module
    # defines its own sync task that runs before devenv:enterShell.
    #
    # We keep uv.enable = true for the uv package, but override UV_PROJECT_ENVIRONMENT
    # to empty so uv uses project-local .venv directories instead of a single shared venv.
    languages.python.enable = true;
    languages.python.version = config.darkmatter.python.version;
    languages.python.venv.enable = false;
    languages.python.uv.enable = true;
    languages.python.uv.sync.enable = false;

    # Python packages
    packages = with pkgs;
      [
        uv
      ]
      ++ lib.optionals config.darkmatter.python.withPostgres [
        postgresql
      ];
  };
}
