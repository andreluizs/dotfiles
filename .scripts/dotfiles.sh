#!/bin/bash
#===============================================================================
#
#          FILE: dotfiles.sh
#
#         USAGE: ./dotfiles.sh
#
#   DESCRIPTION: Script para realizar auto push dos dotfiles.
#
#        AUTHOR: André Luiz dos Santos (andreluizs@live.com), 
#       CREATED: 18/02/2018
#      REVISION: 0.01
#===============================================================================

dotfiles="/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME"

cd ~
$dotfiles pull
$dotfiles status

if [ $? -eq 0 ]; then
    echo "Push realizado com sucesso!"
else
    echo "Houve uma falha ao realizar o push!"
fi

# $dotfiles add -u
# $dotfiles commit -m "Auto push"
# $dotfiles push
