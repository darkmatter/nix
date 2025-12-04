{
  pkgs,
  lib,
  ...
}: {
  files."actionlint.yaml".text = lib.stripIndent ''
    rules:
      workflow-name-matches-path:
        enabled: true
        level: error
        message: 'Workflow name must match path'
        path: '**/*.yaml'
        path: '**/*.yml'
        path: '**/*.json'
        path: '**/*.toml'
        path: '**/*.md'
  '';
}
