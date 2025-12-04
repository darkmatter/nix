# Modules index - import this to get all devenv modules
# Usage: imports = [ ./tooling/nix/modules ];
{ ... }:
{
  imports = [
    ./apps
    ./ci
    ./files
    ./git-hooks
    ./languages
    ./formatting
    ./vscode
    ./scripts
    ./packages

  ];
}
