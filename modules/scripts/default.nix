# Modules index - import this to get all devenv modules
# Usage: imports = [ ./tooling/nix/modules ];
{ ... }:
{
  imports = [
    ./motd.nix
  ];
}
