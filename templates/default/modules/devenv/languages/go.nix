# Go language module for devenv
# Provides Go tooling, CGO configuration, and common Go development packages
{
  pkgs,
  lib,
  config,
  ...
}: let
  devPkgs = [
    pkgs.delve
    pkgs.gomodifytags
    pkgs.impl
    pkgs.go-tools
    pkgs.gopls
    pkgs.gotests
    pkgs.golangci-lint
    pkgs.golangci-lint-langserver
    pkgs.gofumpt
    pkgs.golines
  ];
  requiredPkgs =
    [
      pkgs.delve
    ]
    ++ lib.optionals config.darkmatter.go.enableCGO [
      pkgs.gcc
      pkgs.pkg-config
    ]
    ++ lib.optionals (config.darkmatter.go.enableCGO && pkgs.stdenv.isLinux) [
      pkgs.glibc
      pkgs.glibc.dev
    ];
in {
  options.darkmatter.go = {
    enable = lib.mkEnableOption "Go language support";
    profile = lib.mkOption {
      type = lib.types.enum [
        "dev"
        "ci"
        "production"
      ];
      default = "dev";
      description = "The profile to use for Go development";
    };
    enableCGO = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable CGO for packages requiring C dependencies";
    };
  };

  config = lib.mkIf config.darkmatter.go.enable {
    # CGO environment variables
    env = lib.mkIf config.darkmatter.go.enableCGO {
      CGO_ENABLED = "1";
      GOBIN = config.env.GOPATH + "/bin";
      # Platform-specific CGO flags for DuckDB compatibility
      MACOSX_DEPLOYMENT_TARGET =
        if pkgs.stdenv.isDarwin
        then "14.0"
        else "";
      CGO_CFLAGS =
        if pkgs.stdenv.isDarwin
        then "-mmacosx-version-min=14.0"
        else "";
      CGO_LDFLAGS =
        if pkgs.stdenv.isDarwin
        then "-mmacosx-version-min=14.0"
        else "";
    };

    # Go language configuration (uses devenv's built-in Go support)
    languages.go.enable = true;
    languages.go.package = lib.mkDefault pkgs.go_1_25;
    languages.go.enableHardeningWorkaround = true;

    # Go development packages
    packages = requiredPkgs ++ lib.optionals (config.darkmatter.go.profile == "dev") devPkgs;
    git-hooks.hooks.gofmt.enable = true;
    git-hooks.hooks.govet.enable = true;
    git-hooks.hooks.golangci-lint.enable = true;
    git-hooks.hooks.gopls.enable = true;
    git-hooks.hooks.gotests.enable = true;
  };
}
