# Devenv modules - import these in your devenv.nix
# These modules require devenv and use devenv-specific options like
# packages, scripts, languages, git-hooks, etc.
#
# Usage in consuming flakes:
#   # devenv.nix
#   imports = [ inputs.darkmatter.devenvModules.default ];
#   darkmatter.go.enable = true;
#
{...}: {
  imports = [
    ./apps
    ./ci
    ./files
    ./git-hooks.nix
    ./languages
    ./packages.nix
    ./scripts
    ./vscode
  ];
}
