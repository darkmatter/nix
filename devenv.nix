{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

{
  # https://devenv.sh/basics/
  env.STARSHIP_CONFIG = "${config.git.root}/extra/starship.toml";

  # https://devenv.sh/packages/
  packages = [
    pkgs.git
    pkgs.starship
    pkgs.nerd-fonts.monaspace
  ];

  # https://devenv.sh/languages/
  # languages.rust.enable = true;
  languages.nix.enable = true;

  # https://devenv.sh/processes/
  # processes.dev.exec = "${lib.getExe pkgs.watchexec} -n -- ls -la";

  # https://devenv.sh/services/
  # services.postgres.enable = true;

  # https://devenv.sh/scripts/
  scripts.hello.exec = ''
    echo hello from $GREET
  '';

  # https://devenv.sh/basics/
  enterShell = ''
    export FONT_DIR="${pkgs.nerd-fonts.monaspace}/share/fonts/opentype/NerdFonts/Monaspice"
    export FONT_NAME="MonaspiceNeNerdFont-Light.otf"
    export FONT_PATH="$FONT_DIR/$FONT_NAME"
    # fc-cache -f -v

    if [ -f "$FONT_PATH" ]; then
      echo "Font installed at $FONT_PATH"
    else
      echo "Font not found at $FONT_PATH"
      exit 1
    fi

    eval "$(${pkgs.starship}/bin/starship init $SHELL)"
  '';

  # https://devenv.sh/tasks/
  # tasks = {
  #   "myproj:setup".exec = "mytool build";
  #   "devenv:enterShell".after = [ "myproj:setup" ];
  # };

  # https://devenv.sh/tests/
  enterTest = ''
    echo "Running tests"
    git --version | grep --color=auto "${pkgs.git.version}"
  '';

  # https://devenv.sh/git-hooks/
  git-hooks.hooks.shellcheck.enable = true;

  cachix.enable = true;
  cachix.pull = [ "darkmatter" ];
  cachix.push = "darkmatter";

  # See full reference at https://devenv.sh/reference/options/
}
