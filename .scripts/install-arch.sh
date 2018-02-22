#!/bin/bash
set -e

# Dados pessoais.
USER=andre
USER_NAME='André Luiz'
USER_PASSWD=andre
ROOT_PASSWD=root
HOST=arch-note

# Dados do HD
HD=/dev/sda
BOOT_FS='vfat -F32'
HOME_FS=ext4
ROOT_FS=ext4

# Configurações da Região
KEYBOARD_LAYOUT=br-abnt2
MIRROR='http://linorg.usp.br/archlinux/$repo/os/$arch'
LANGUAGE=pt_BR
LOCALE=America/Sao_Paulo
NTP='NTP=0.arch.pool.ntp.org 1.arch.pool.ntp.org2.arch.pool.ntp.org 3.arch.pool.ntp.org``\nFallbackNTP=FallbackNTP=0.pool.ntp.org 1.pool.ntp.org 0.fr.pool.ntp.org'

# Funções
iniciar() {
    local ERR=0
    
    echo
    echo '[#]------ CONFIGURANDO O TECLADO -----[#]'
    echo '[#]-----------------------------------[#]'
    loadkeys $KEYBOARD_LAYOUT
    echo '[#]- OPERAÇÃO REALIZADA COM SUCESSO! -[#]'
    
    echo
    echo '[#]------ CONFIGURANDO O MIRROR ------[#]'
    echo '[#]-----------------------------------[#]'
    sed -i '1s/^/' echo $MIRROR'\n/' /etc/pacman.d/mirrorlist
    echo '[#]- OPERAÇÃO REALIZADA COM SUCESSO! -[#]'
    
    echo 
    echo '[#]------ ATUALIZANDO O SISTEMA ------[#]'
    echo '[#]-----------------------------------[#]'
    pacman -Syu 1>/dev/null || ERR=1
    echo '[#]- OPERAÇÃO REALIZADA COM SUCESSO! -[#]'
    
    if [[ $ERR -eq 1 ]]; then
                echo
                echo '[!]--------- ERRO NA OPERAÇÃO --------[!]'
                exit 1
        fi
}

# Chamada das Funções
clear
iniciar