# Single owner for login/interactive PATH and shell startup. The shells
# themselves (bash, fish, man-db) come from pacman: nothing here may put a Nix
# copy of them ahead of /usr/bin.
{ config, pkgs, ... }:
{
  home.sessionVariables = {
    PNPM_HOME = "${config.home.homeDirectory}/.local/share/pnpm"; # pnpm puts global bins in $PNPM_HOME/bin
  };
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.local/share/pnpm/bin"
    "$HOME/.opencode/bin"
  ];
  programs.bash = {
    enable = true;
    package = null;
    historyFile = "${config.xdg.stateHome}/bash/history";
    bashrcExtra = ''
      # If not running interactively, don't do anything
      [[ $- != *i* ]] && return
      alias ls='ls --color=auto'
      alias grep='grep --color=auto'
      PS1='[\u@\h \W]\$ '
    '';
  };
  programs.fish = {
    enable = true;
    # The module formats config.fish with fish_indent at build time, so it needs
    # a package providing that; the fish binary itself stays pacman's.
    package = pkgs.runCommand "fish-indent-only" { } ''
      mkdir -p $out/bin
      ln -s ${pkgs.fish}/bin/fish_indent $out/bin/fish_indent
    '';
    generateCompletions = false;
    interactiveShellInit = ''
      # Keep CachyOS fish integration, then silence the greeting.
      if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
        source /usr/share/cachyos-fish-config/cachyos-config.fish
      end
      functions -e fish_greeting 2>/dev/null; function fish_greeting; end
      # Per-project environments (.envrc, e.g. `use flake`).
      if command -q direnv
        direnv hook fish | source
      end
    '';
  };
  # man-db and shared-mime-info from pacman; HM's copies would shadow them.
  programs.man.enable = false;
  xdg.mime.enable = false;

  # zsh is not an interactive shell here, but tools (e.g. Claude Code) run
  # commands through it; keep its startup file valid and empty.
  home.file.".zshrc".text = "# Intentionally empty: fish is the login shell.\n";
}
