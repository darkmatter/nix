# CI verification tasks
{
  pkgs,
  config,
  lib,
  ...
}:
let
  gitRoot =
    if config.git.root != null then
      config.git.root
    else if lib.pathExists (config.devenv.root + "/pnpm-workspace.yaml") then
      config.devenv.root
    else
      builtins.dirOf (builtins.dirOf config.devenv.root);
in
{
  options.ci = {
    buildPath = lib.mkOption {
      type = lib.types.str;
      description = "The path to the build directory";
      default = gitRoot;
    };
  };

  tasks."ci:checks:all" = {
    cwd = gitRoot;
    exec = ''
      set -euo pipefail
      CI=''${CI:-}

      ${pkgs.turbo}/bin/turbo run checks --affected  "$@"
    '';
  };

  tasks."ci:verify-devenv" = {
    description = "Verify devenv configuration builds successfully (for CI)";
    exec = ''
      set -euo pipefail
      echo "Verifying devenv configuration..."
      # This task validates that the nix evaluation succeeds by running this task itself
      # If we reach this point, the devenv configuration is valid
      echo "✓ devenv configuration is valid"
    '';
  };

  tasks."ci:check-purity" = {
    description = "Check for hardcoded user paths in nix store derivations";
    exec = ''
      set -euo pipefail
      echo "Checking for hardcoded paths in nix store..."

      # Get the devenv profile path
      PROFILE=$(devenv info 2>/dev/null | ${pkgs.gnugrep}/bin/grep "DEVENV_PROFILE:" | ${pkgs.gawk}/bin/awk '{print $2}')

      if [ -z "$PROFILE" ]; then
        echo "Could not determine DEVENV_PROFILE"
        exit 1
      fi

      # Check for common user path patterns in the store
      if ${pkgs.gnugrep}/bin/grep -r "/Users/\|/home/" "$PROFILE" 2>/dev/null | ${pkgs.gnugrep}/bin/grep -v "^Binary"; then
        echo "✗ Found hardcoded user paths in nix store!"
        exit 1
      fi

      echo "✓ No hardcoded user paths found in nix store"
    '';
  };

}
