{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
let
  agenix = inputs.agenix.packages.${pkgs.stdenv.system}.default;
  secretsDir = "${config.devenv.root}/secrets";
in
{
  imports = [
    ./modules/devenv
  ];
  # https://devenv.sh/basics/
  # env.STARSHIP_CONFIG = "${config.devenv.root}/extra/starship.toml";
  env.AGENIX_SECRETS_DIR = secretsDir;

  # https://devenv.sh/packages/
  packages = [
    pkgs.git
    pkgs.starship
    pkgs.nerd-fonts.monaspace
    agenix
    pkgs.age
  ];

  # https://devenv.sh/languages/
  # languages.rust.enable = true;
  languages.nix.enable = true;

  difftastic.enable = true;

  # https://devenv.sh/processes/
  # processes.dev.exec = "${lib.getExe pkgs.watchexec} -n -- ls -la";

  # https://devenv.sh/services/
  # services.postgres.enable = true;

  # https://devenv.sh/scripts/
  scripts.hello.exec = ''
    echo hello from $GREET
  '';

  # Agenix secret management scripts
  scripts.secrets-edit = {
    description = "Edit an encrypted secret with agenix";
    exec = ''
      if [ -z "$1" ]; then
        echo "Usage: secrets-edit <secret-name.age>"
        echo "Example: secrets-edit api-key.age"
        exit 1
      fi
      cd "${secretsDir}"
      ${agenix}/bin/agenix -e "$1"
    '';
  };

  scripts.secrets-rekey = {
    description = "Re-encrypt all secrets when public keys change";
    exec = ''
      cd "${secretsDir}"
      ${agenix}/bin/agenix -r
    '';
  };

  scripts.secrets-list = {
    description = "List all encrypted secrets";
    exec = ''
      echo "Encrypted secrets in ${secretsDir}:"
      ls -la "${secretsDir}"/*.age 2>/dev/null || echo "No secrets found"
    '';
  };

  scripts.secrets-decrypt = {
    description = "Decrypt a secret to stdout (for debugging)";
    exec = ''
      if [ -z "$1" ]; then
        echo "Usage: secrets-decrypt <secret-name.age>"
        exit 1
      fi
      ${pkgs.age}/bin/age -d -i ~/.ssh/id_ed25519 "${secretsDir}/$1" 2>/dev/null || \
      ${pkgs.age}/bin/age -d -i ~/.ssh/id_rsa "${secretsDir}/$1"
    '';
  };

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
