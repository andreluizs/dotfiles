#!/bin/bash
set -e

# Dados pessoais.
USER=andre
USER_NAME="André Luiz"
USER_PASSWD=andre
ROOT_PASSWD=root
HOST=arch-note

# Dados do HD
HD=/dev/sda
BOOT_FS="vfat -F32"
HOME_FS=ext4
ROOT_FS=ext4

# Configurações da Região
KEYBOARD_LAYOUT=br-abnt2
MIRROR="http://linorg.usp.br/archlinux/$repo/os/$arch"
LANGUAGE=pt_BR
LOCALE=America/Sao_Paulo
NTP="NTP=0.arch.pool.ntp.org 1.arch.pool.ntp.org2.arch.pool.ntp.org 3.arch.pool.ntp.org``\nFallbackNTP=FallbackNTP=0.pool.ntp.org 1.pool.ntp.org 0.fr.pool.ntp.org"

# Funções
iniciar() {
    echo
    echo "[#]--- CONFIGURANDO O TECLADO ---[#]"
    echo "[#]------------------------------[#]"
    loadkeys $KEYBOARD_LAYOUT
    echo "[#]----- OPERAÇÃO REALIZADA -----[#]"
    echo
    echo "[#]--- CONFIGURANDO O MIRROR ----[#]"
    echo "[#]------------------------------[#]"
    sed -i '1s/^/$MIRROR\n/' /etc/pacman.d/mirrorlist
    echo "[#]----- OPERAÇÃO REALIZADA -----[#]"
    echo 
    echo "[#]--- ATUALIZANDO O SISTEMA ----[#]"
    echo "[#]------------------------------[#]"
    pacman -Syu &> /dev/null
    echo "[#]----- OPERAÇÃO REALIZADA -----[#]"
    echo
}

# Chamada das Funções
clear
iniciar