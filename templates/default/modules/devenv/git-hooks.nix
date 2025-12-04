# Git hooks configuration (pre-commit)
{pkgs, ...}: let
  # In CI, disable git-hooks
  isCI = builtins.getEnv "CI" == "true";
  enableGitHooks =
    if isCI
    then false
    else true;
in {
  git-hooks.package = pkgs.prek; # pre-commit re-written in rust
  git-hooks.install.enable = enableGitHooks;

  git-hooks.hooks = {
    # ===== Nix =====
    deadnix.enable = enableGitHooks; # Scan for dead code (unused bindings)
    # statix.enable = enableGitHooks; # Disabled - repeated keys pattern is intentional in devenv modules
    alejandra.enable = enableGitHooks; # Nix formatter (already in treefmt)

    # ===== Shell =====
    # shellcheck.enable = enableGitHooks; # Lint shell scripts
    beautysh.enable = enableGitHooks; # Format shell scripts
    # shfmt.enable = enableGitHooks; # Format shell scripts

    # ===== Markdown =====
    # comrak.enable = enableGitHooks; # Markdown formatter - disabled due to multi-file issues
    # markdownlint.enable = enableGitHooks; # Lint markdown files - disabled, too many false positives

    # ===== YAML =====
    yamlfmt.enable = enableGitHooks; # Lint YAML files
    # yamllint.enable = enableGitHooks; # Lint YAML files

    # ===== TOML =====
    check-toml.enable = enableGitHooks; # Validate TOML syntax

    # ===== JSON =====
    check-json.enable = enableGitHooks; # Validat`e JSON syntax

    # ===== Docker =====
    # hadolint.enable = enableGitHooks; # Dockerfile linter

    # ===== GitHub Actions =====
    actionlint.enable = enableGitHooks; # Lint GitHub Actions workflows

    # ===== Security =====
    detect-private-keys.enable = enableGitHooks; # Prevent committing private keys
    ripsecrets.enable = enableGitHooks; # Prevent committing secrets

    # ===== Git hygiene =====
    check-added-large-files.enable = enableGitHooks; # Prevent large files
    check-merge-conflicts.enable = enableGitHooks; # Detect merge conflict markers
    check-symlinks.enable = enableGitHooks; # Find broken symlinks
    trim-trailing-whitespace.enable = enableGitHooks; # Clean up trailing whitespace
    end-of-file-fixer.enable = enableGitHooks; # Ensure files end with newline
    mixed-line-endings.enable = enableGitHooks; # Consistent line endings
    check-case-conflicts.enable = enableGitHooks; # Prevent case-insensitive conflicts

    # ===== Commit messages =====
    commitizen.enable = enableGitHooks; # Enforce conventional commits

    # ===== Spell checking =====
    # typos.enable = enableGitHooks; # Fast source code spell checker

    # ===== Turbo =====
    # ===== Python =====
    ruff.enable = enableGitHooks; # Fast Python linter (replaces flake8, isort, etc.)
    ruff-format.enable = enableGitHooks; # Python formatter
    # pyright.enable = enableGitHooks; # Disabled - use custom hook below for monorepo support

    # Custom pyright hook that runs from each project's directory
    # This ensures pyright uses the correct venv and config for each project
    pyright-monorepo = {
      enable = enableGitHooks;
      name = "pyright-monorepo";
      entry = toString (
        pkgs.writeShellScript "pyright-monorepo" ''
          set -euo pipefail

          # Group files by their project directory (where pyproject.toml exists)
          declare -A project_files

          for file in "$@"; do
            # Find the nearest parent directory with pyproject.toml
            dir=$(dirname "$file")
            while [ "$dir" != "/" ] && [ "$dir" != "." ]; do
              if [ -f "$dir/pyproject.toml" ]; then
                # Check if this project has a pyright config
                if ${pkgs.gnugrep}/bin/grep -q '\[tool.pyright\]' "$dir/pyproject.toml" 2>/dev/null; then
                  # Get relative path from project dir
                  rel_file="''${file#$dir/}"
                  if [ -z "''${project_files[$dir]:-}" ]; then
                    project_files[$dir]="$rel_file"
                  else
                    project_files[$dir]="''${project_files[$dir]} $rel_file"
                  fi
                  break
                fi
              fi
              dir=$(dirname "$dir")
            done
          done

          # Run pyright for each project
          exit_code=0
          for project_dir in "''${!project_files[@]}"; do
            echo "Running pyright in $project_dir..."
            files=''${project_files[$project_dir]}
            if ! (cd "$project_dir" && ${pkgs.pyright}/bin/pyright $files); then
              exit_code=1
            fi
          done

          exit $exit_code
        ''
      );
      files = "\\.py$";
      pass_filenames = true;
      stages = ["pre-commit"];
    };
    # ===== JavaScript/TypeScript =====
    # biome.enable = enableGitHooks; # Unified linting & formatting for JS/TS/JSON
    # Format and lint using turbo with --affected flag
    turbo-format = {
      enable = enableGitHooks;
      name = "turbo-format";
      entry = "${pkgs.pnpm}/bin/pnpm turbo format --affected";
      pass_filenames = false;
      stages = ["pre-commit"];
      extraPackages = [
        pkgs.git
        pkgs.nodejs
        pkgs.golangci-lint
        pkgs.pyright
        pkgs.ruff
      ];
    };
    turbo-lint = {
      enable = enableGitHooks;
      name = "turbo-lint";
      entry = "${pkgs.pnpm}/bin/pnpm turbo lint --affected";
      pass_filenames = false;
      stages = ["pre-commit"];
      extraPackages = [
        pkgs.git
        pkgs.nodejs
        pkgs.golangci-lint
        pkgs.pyright
        pkgs.ruff
      ];
    };
    gptcommit.enable = enableGitHooks; # AI-assisted commit messages
  };
}
