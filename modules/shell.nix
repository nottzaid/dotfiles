# Single owner for login/interactive PATH. Replaces bin/env + bin/env.fish +
# uwsm/env PATH preamble + .profile/.bash_profile/.bashrc triple-source.
{ config, lib, ... }:
{
  home.sessionVariables = {
    PNPM_HOME = "${config.home.homeDirectory}/.local/share/pnpm/bin";
  };
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.local/share/pnpm/bin"
    "$HOME/.opencode/bin"
  ];
  programs.bash = {
    enable = true;
    profileExtra = ''
      # Managed by Home Manager (modules/shell.nix). Login env comes from
      # hm-session-vars.sh; no manual sourcing of ~/.local/bin/env needed.
    '';
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
    interactiveShellInit = ''
      # Keep CachyOS fish integration, then override greeting (was: comment hack in config.fish).
      if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
        source /usr/share/cachyos-fish-config/cachyos-config.fish
      end
      functions -e fish_greeting 2>/dev/null; function fish_greeting; end
      # Guarded brew (was: unguarded eval that fails noisily when brew is absent).
      if test -x /home/linuxbrew/.linuxbrew/bin/brew
        eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
      end
    '';
  };
}
