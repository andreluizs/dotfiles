#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias tty-clock='tty-clock -scC 7 -f %d/%m/%Y'

PS1='[\u@\h \W]\$ '
alias dotfiles='/usr/bin/git --git-dit=/home/andre/.dotfiles/ --work-tree=/home/andre'
