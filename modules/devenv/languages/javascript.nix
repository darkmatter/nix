# JavaScript/TypeScript language module for devenv
# Provides Node.js with pnpm and corepack
{
  pkgs,
  lib,
  config,
  ...
}: {
  options.darkmatter.javascript = {
    enable = lib.mkEnableOption "JavaScript/TypeScript language support";
    nodeVersion = lib.mkOption {
      type = lib.types.package;
      default = pkgs.nodejs_24;
      description = "Node.js package to use";
    };
    autoInstall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Automatically run pnpm install on shell entry";
    };
  };

  config = lib.mkIf config.darkmatter.javascript.enable {
    languages.javascript.enable = true;
    languages.javascript.package = config.darkmatter.javascript.nodeVersion;
    languages.javascript.corepack.enable = true;
    languages.javascript.pnpm.enable = true;
    languages.javascript.pnpm.install.enable = config.darkmatter.javascript.autoInstall;
    languages.typescript.enable = true;
  };
}
