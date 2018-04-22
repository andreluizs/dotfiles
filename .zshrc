# Lang
export LANG=pt_BR.UTF-8

# Usuario 
DEFAULT_USER=`whoami`


autoload -U colors && colors

PS1="[%{$fg_bold[red]%}%n%{$reset_color%}@%{$fg[blue]%}%m %{$fg[yellow]%}%~%{$reset_color%}]:% "

# Aliases
alias dotfiles="/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME"
alias ls='ls --color=auto'
