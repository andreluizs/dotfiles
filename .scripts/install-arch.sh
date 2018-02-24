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
    sed -i "1i $MIRROR" /etc/pacman.d/mirrorlist
    
}

particionar_hd(){
    local ERR=0

    echo
    echo '[-#-] CRIANDO A TABELA DE PARTIÇÃO'
    parted -s $HD mklabel gpt &> /dev/null
    
    echo
    echo '[-#-] CRIANDO A PARTIÇÃO /BOOT'
    parted $HD mkpart primary fat32 0% 512MB 1>/dev/null || ERR=1
    parted $HD set 1 boot on 1>/dev/null || ERR=1

    echo
    echo '[-#-] CRIANDO A PARTIÇÃO SWAP'
    parted $HD mkpart primary linux-swap 512MB 4608MB 1>/dev/null || ERR=1
    
    echo
    echo '[-#-] CRIANDO A PARTIÇÃO /ROOT'
    parted $HD mkpart primary ext4 4608MB 35328MB 1>/dev/null || ERR=1

    echo
    echo '[-#-] CRIANDO A PARTIÇÃO /HOME'
    parted $HD mkpart primary ext4 35328MB 100% 1>/dev/null || ERR=1

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
    mkfs.fat -F32 $HD'1' -n BOOT 1>/dev/null || ERR=1

    echo
    echo '[-#-] FORMATANDO A PARTIÇÃO SWAP'
    mkswap $HD'2' || ERR=1
    swapon $HD'2' || ERR=1

    echo
    echo '[-#-] FORMATANDO A PARTIÇÃO /ROOT'
    mkfs.ext4 $HD'3' -L ROOT 1>/dev/null || ERR=1

    echo
    echo '[-#-] FORMATANDO A PARTIÇÃO /HOME'
    mkfs.ext4 $HD'4' -L HOME 1>/dev/null || ERR=1
   
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