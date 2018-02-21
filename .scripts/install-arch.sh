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
BOOT_FS=vfat -F32
HOME_FS=ext4
ROOT_FS=ext4

# Configurações
KEYBOARD_LAYOUT=br-abnt2
LANGUAGE=pt_BR
LOCALE=America/Sao_Paulo

# Funções
iniciar(){
    echo 
    echo " [X] --- Configurando o Teclado --- [X]"
    loadkeys $KEYBOARD_LAYOUT
}

iniciar
