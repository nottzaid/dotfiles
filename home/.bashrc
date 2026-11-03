# Interactive Bash (fish is the login shell; Bash serves scripts and tools).
[[ $- == *i* ]] || return
[[ -n ${DOTFILES_PROFILE-} ]] || . ~/.profile

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

HISTFILE=~/.local/state/bash/history
HISTFILESIZE=100000
HISTSIZE=10000
mkdir -p ~/.local/state/bash
shopt -s histappend extglob globstar checkjobs

[[ -v BASH_COMPLETION_VERSINFO ]] || . /usr/share/bash-completion/bash_completion
