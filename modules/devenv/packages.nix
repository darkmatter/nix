{
  pkgs,
  ...
}:
{
  packages = [
    pkgs.starship
    pkgs.nil
    pkgs.nixd
    pkgs.bashInteractive
    pkgs.neovim
  ];
}
