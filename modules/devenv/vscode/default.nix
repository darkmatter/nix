# VSCode settings management module
# Reads existing .vscode/settings.json, merges with configured overrides, and writes back
{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.vscode;

  # Path to the VSCode settings file
  settingsPath = "${config.devenv.root}/.vscode/settings.json";

  # Script to merge settings
  mergeSettingsScript = pkgs.writeShellScript "merge-vscode-settings" ''
    set -euo pipefail

    SETTINGS_PATH="$1"
    OVERRIDES="$2"

    # Create .vscode directory if it doesn't exist
    mkdir -p "$(dirname "$SETTINGS_PATH")"

    # Read existing settings or start with empty object
    if [ -f "$SETTINGS_PATH" ]; then
      # Strip comments from JSONC (VSCode settings can have comments)
      EXISTING=$(${pkgs.jq}/bin/jq -c '.' "$SETTINGS_PATH" 2>/dev/null || echo '{}')
    else
      EXISTING='{}'
    fi

    # Merge: existing settings + overrides (overrides take precedence)
    echo "$EXISTING" | ${pkgs.jq}/bin/jq -S --argjson overrides "$OVERRIDES" '. * $overrides' > "$SETTINGS_PATH.tmp"
    mv "$SETTINGS_PATH.tmp" "$SETTINGS_PATH"

    echo "VSCode settings updated at $SETTINGS_PATH"
  '';

  # Convert Nix attrset to JSON for the overrides
  overridesJson = builtins.toJSON cfg.settings;
in {
  options.vscode = {
    enable = lib.mkEnableOption "VSCode settings management";

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {};
      description = ''
        VSCode settings to merge into .vscode/settings.json.
        These settings will override any existing values with the same keys.
        Nested objects are deep-merged.
      '';
      example = lib.literalExpression ''
        {
          "editor.formatOnSave" = true;
          "python.defaultInterpreterPath" = "''${workspaceFolder}/.venv/bin/python";
          "terminal.integrated.defaultProfile.osx" = "devenv";
        }
      '';
    };

    settingsFile = lib.mkOption {
      type = lib.types.str;
      default = settingsPath;
      description = "Path to the VSCode settings.json file";
    };
  };

  config = lib.mkIf cfg.enable {
    # Add a task to sync VSCode settings on devenv activation
    tasks."vscode:settings:sync" = {
      exec = "${mergeSettingsScript} ${lib.escapeShellArg cfg.settingsFile} ${lib.escapeShellArg overridesJson}";
      before = ["devenv:enterShell"];
    };

    # Add a script to manually sync VSCode settings
    scripts.vscode-sync-settings = {
      description = "Sync VSCode settings with Nix-configured overrides";
      exec = ''
        ${mergeSettingsScript} ${lib.escapeShellArg cfg.settingsFile} ${lib.escapeShellArg overridesJson}
      '';
    };

    # Add a script to view the current overrides
    scripts.vscode-show-overrides = {
      description = "Show the VSCode settings overrides configured in Nix";
      exec = ''
        echo "VSCode settings overrides from Nix configuration:"
        echo ${lib.escapeShellArg overridesJson} | ${pkgs.jq}/bin/jq '.'
      '';
    };

    # Add a script to diff current settings with what would be applied
    scripts.vscode-diff-settings = {
      description = "Show diff between current and merged VSCode settings";
      exec = ''
        SETTINGS_PATH=${lib.escapeShellArg cfg.settingsFile}
        OVERRIDES=${lib.escapeShellArg overridesJson}

        if [ ! -f "$SETTINGS_PATH" ]; then
          echo "No existing settings.json found at $SETTINGS_PATH"
          echo "Would create with:"
          echo "$OVERRIDES" | ${pkgs.jq}/bin/jq -S '.'
          exit 0
        fi

        # Get current settings (strip comments)
        CURRENT=$(${pkgs.jq}/bin/jq -S '.' "$SETTINGS_PATH" 2>/dev/null || echo '{}')

        # Get merged settings
        MERGED=$(echo "$CURRENT" | ${pkgs.jq}/bin/jq -S --argjson overrides "$OVERRIDES" '. * $overrides')

        # Show diff
        ${pkgs.diffutils}/bin/diff -u \
          <(echo "$CURRENT" | ${pkgs.jq}/bin/jq -S '.') \
          <(echo "$MERGED") \
          || true
      '';
    };
  };
}
