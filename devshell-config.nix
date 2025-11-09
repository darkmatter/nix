# Shared devshell configuration
{ devshell }:
devshell.mkShell {
  imports = [ (devshell.importTOML ./devshell.toml) ];
  devshell.interactive.powerline = {
    text = ''
      # Setup powerline-go prompt
      INTERACTIVE_BASHPID_TIMER="/tmp/''${USER}.START.$$"
      PS0='$(echo $SECONDS > "$INTERACTIVE_BASHPID_TIMER")'

      function _update_ps1() {
        local __ERRCODE=$?

        local __DURATION=0
        if [ -e $INTERACTIVE_BASHPID_TIMER ]; then
          local __END=$SECONDS
          local __START=$(cat "$INTERACTIVE_BASHPID_TIMER")
          __DURATION="$(($__END - ''${__START:-__END}))"
          rm -f "$INTERACTIVE_BASHPID_TIMER"
        fi
        PS1="$(powerline-go \
          -error $__ERRCODE \
          -shell bash \
          -modules aws,docker,venv,duration,ssh,cwd,perms,git,hg,exit,root \
          -modules-right jobs \
          -duration $__DURATION \
          -cwd-mode fancy \
          -max-width 0 \
          -cwd-max-depth 3 \
          -newline \
          -cwd-max-dir-size 8 \
          -theme ${./extra/powerline-theme.json} \
          )"
      }

      if [ "$TERM" != "linux" ] && command -v powerline-go &>/dev/null; then
        PROMPT_COMMAND="_update_ps1''${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
      fi
    '';
    deps = [ ];
  };
}
