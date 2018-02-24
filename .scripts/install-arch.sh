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
BOOT_FS='ESP fat32'
HOME_FS=ext4
ROOT_FS=ext4

# Tamanho das partições em MB
BOOT_SIZE=512
SWAP_SIZE=4096
ROOT_SIZE=30720
#HOME_SIZE=RESTO DO HD

BOOT_START=1
BOOT_END=$(($BOOT_SIZE + $BOOT_START))
SWAP_START=$BOOT_END
SWAP_END=$(($SWAP_START + $SWAP_SIZE))
ROOT_START=$SWAP_END
ROOT_END=$(($ROOT_START + $ROOT_SIZE))
HOME_START=$ROOT_END
#HOME_END=RESTO DO HD

# Configurações da Região
KEYBOARD_LAYOUT='br abnt2'
MIRROR='Server = http://linorg.usp.br/archlinux/$repo/os/$arch'
LANGUAGE=pt_BR
LOCALE=America/Sao_Paulo
NTP='NTP=0.arch.pool.ntp.org 1.arch.pool.ntp.org2.arch.pool.ntp.org 3.arch.pool.ntp.org``\nFallbackNTP=FallbackNTP=0.pool.ntp.org 1.pool.ntp.org 0.fr.pool.ntp.org'

# Funções
iniciar() {
    local ERR=0

    echo
    echo '[-#-] CONFIGURANDO A HORA'
    timedatectl set-ntp true

    echo
    echo '[-#-] CONFIGURANDO O TECLADO'
    localectl set-x11-keymap $KEYBOARD_LAYOUT
    
    echo
    echo '[-#-] CONFIGURANDO O MIRROR'
    sed -i "1i $MIRROR" ~/.scripts/mirrorlist
    
}

particionar_hd(){
    local ERR=0

    echo
    echo '[-#-] CRIANDO A TABELA DE PARTIÇÃO'
    parted -s $HD mklabel gpt &> /dev/null
    
    echo
    echo '[-#-] CRIANDO A PARTIÇÃO /BOOT'
    parted -s $HD mkpart primary $BOOT_FS $BOOT_START $BOOT_END 1>/dev/null || ERR=1
    parted -s $HD set 1 boot on 1>/dev/null || ERR=1

    echo
    echo '[-#-] CRIANDO A PARTIÇÃO SWAP'
    parted -s $HD mkpart primary linux-swap $SWAP_START $SWAP_END 1>/dev/null || ERR=1
    
    echo
    echo '[-#-] CRIANDO A PARTIÇÃO /ROOT'
    parted -s $HD mkpart primary $ROOT_FS $ROOT_START $ROOT_END 1>/dev/null || ERR=1

    echo
    echo '[-#-] CRIANDO A PARTIÇÃO /HOME'
    parted -s -- $HD mkpart primary $HOME_FS $HOME_START 100% 1>/dev/null || ERR=1

    if [[ $ERR -eq 1 ]]; then
        echo
        echo '[ ! ] ERRO AO CRIAR AS PARTIÇÕES'
        exit 1
    fi

}


    # echo 
    # echo '[#]------ ATUALIZANDO O SISTEMA ------[#]'
    # pacman -Syu 1>/dev/null || ERR=1
    
formatar_particao(){
    local ERR=0

    echo
    echo '[-#-] FORMATANDO A PARTIÇÃO /BOOT'
    mkfs.$BOOT_FS /dev/sda1 -L BOOT 1>/dev/null || ERR=1

    echo
    echo '[-#-] FORMATANDO A PARTIÇÃO SWAP'
    mkswap /dev/sda2 || ERR=1
    swapon /dev/sda2 || ERR=1

    echo
    echo '[-#-] FORMATANDO A PARTIÇÃO /ROOT'
    mkfs.$ROOT_FS /dev/sda3 -L ROOT 1>/dev/null || ERR=1

    echo
    echo '[-#-] FORMATANDO A PARTIÇÃO /HOME'
    mkfs.$HOME_FS /dev/sda4 -L HOME 1>/dev/null || ERR=1
   
   if [[ $ERR -eq 1 ]]; then
        echo
        echo '[ ! ] ERRO AO FORMATAR AS PARTIÇÕES'
        exit 1
    fi

}

# Chamada das Funções
clear
iniciar
particionar_hd
formatar_particao