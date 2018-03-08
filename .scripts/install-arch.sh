#!/bin/bash
#===============================================================================
#
#          FILE: install-arch.sh
#
#         USAGE: ./install-arch.sh
#
#   DESCRIPTION: Script para realizar a instalação do Arch Linux.
#
#        AUTHOR: André Luiz dos Santos (andreluizs@live.com),
#       CREATED: 06/03/2018
#      REVISION: 1.00
#===============================================================================

set -o errexit
set -o pipefail

#===============================================================================
#---------------------------------VARIAVEIS-------------------------------------
#===============================================================================
# Cores
readonly VERMELHO='\e[31m\e[1m'
readonly VERDE='\e[32m\e[1m'
readonly AMARELO='\e[33m\e[1m'
readonly AZUL='\e[34m\e[1m'
readonly MAGENTA='\e[35m\e[1m'
readonly NEGRITO='\e[1m'
readonly SEMCOR='\e[0m'

# Usuário
MY_USER=${MY_USER:-'andre'}
MY_USER_NAME=${MY_USER_NAME:-'André Luiz'}
MY_USER_PASSWD=${MY_USER:-'andre'}
ROOT_PASSWD=${ROOT_PASSWD:-'root'}

# HD
HD=${HD:-'/dev/sda'}

# Nome da maquina
HOST=${HOST:-"archlinux"}

# Tamanho das partições em MB
BOOT_SIZE=${BOOT_SIZE:-512}
SWAP_SIZE=${SWAP_SIZE:-4096}
ROOT_SIZE=${ROOT_SIZE:-30720}

# Configurações da Região
KEYBOARD_LAYOUT="br abnt2"
LANGUAGE="pt_BR"
TIMEZONE="America/Sao_Paulo"
NTP="NTP=0.arch.pool.ntp.org 1.arch.pool.ntp.org2.arch.pool.ntp.org 3.arch.pool.ntp.org
FallbackNTP=FallbackNTP=0.pool.ntp.org 1.pool.ntp.org 0.fr.pool.ntp.org"

# Entradas do Bootloader
LOADER_CONF="timeout 0\\ndefault arch"
ARCH_ENTRIE="title Arch Linux\\nlinux /vmlinuz-linux\\ninitrd /initramfs-linux.img\\noptions root=${HD}3 rw"

#===============================================================================
#----------------------------------FUNÇÕES--------------------------------------
#===============================================================================

function _msg() {
    case $1 in
    info)       cor="${VERDE}[I]${SEMCOR}" ;;
    erro)       cor="${VERMELHO}[E]${SEMCOR}" ;;
    quest)      cor="${AZUL}[Q]${SEMCOR}" ;;
    esac
    echo -e "${cor} ${2}"
}

function _chroot() {
    arch-chroot /mnt /bin/bash -c "$1"
}

function bem_vindo() {
    echo -e "${NEGRITO}=================================================${SEMCOR}"
    echo -e "${NEGRITO}BEM VINDO AO INSTALADOR AUTOMÁTICO DO ARCH - UEFI${SEMCOR}"
    echo -e "${NEGRITO}=================================================${SEMCOR}"
    echo
}

function spinner() {
    local pid=$1
    local delay=0.75
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf "${AMARELO}[%c]${SEMCOR}  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

function iniciar() {

    padrao=${padrao:-s}
    _msg quest "Gostaria de realizar a instalação padrão? (${NEGRITO}S/${SEMCOR}n):"
    read -s -en 1 padrao

    if [[ $padrao == "n" ]]; then
        _msg quest 'Informe o nome completo do usuário:'
        read MY_USER_NAME

        _msg quest 'Informe o úsuario:'
        read MY_USER

        _msg quest "Informe o password do usuario: $MY_USER:"
        read -s MY_USER

        _msg quest "Informe o password do usuario: root:"
        read -s ROOT_PASSWD

        _msg quest "Informe o device que será instalado ex:[/dev/sda]:"
        read HD

         _msg quest "Informe o nome da maquina:"
        read HOST
    fi

    echo
    echo -e "${AMARELO}Vá buscar um café, eu cuido do resto!${SEMCOR}"
    
    echo
    _msg info 'Sincronizando a hora.'
    timedatectl set-ntp true

    _msg info "Definindo o teclado para: $KEYBOARD_LAYOUT."
    localectl set-x11-keymap "$KEYBOARD_LAYOUT"

    _msg info 'Procurando o servidor mais rápido.'
    sed -n '/^## Brazil/ {n;p}' /etc/pacman.d/mirrorlist >/etc/pacman.d/mirrorlist.backup
    rankmirrors -n 6 /etc/pacman.d/mirrorlist.backup >/etc/pacman.d/mirrorlist
}

function particionar_hd() {
    local err=0

    # Calculo para criar as partições com o parted
    local boot_start=1
    local boot_end=$((BOOT_SIZE + boot_start))
    local swap_start=$boot_end
    local swap_end=$((swap_start + SWAP_SIZE))
    local root_start=$swap_end
    local root_end=$((root_start + ROOT_SIZE))
    local home_start=$root_end
    local home_end="100%"

    echo
    _msg info 'Definindo a tabela de partição para GPT.'
    parted -s $HD mklabel gpt &> /dev/null

    _msg info "Criando a partição /boot com ${BOOT_SIZE}MB."
    parted $HD mkpart ESP fat32 "${boot_start}MiB" "${boot_end}MiB" 2> /dev/null || err=1
    parted $HD set 1 boot on 2> /dev/null || err=1

    _msg info "Criando a partição swap com ${SWAP_SIZE}MB."
    parted $HD mkpart primary linux-swap "${swap_start}MiB" "${swap_end}MiB" 2> /dev/null || err=1

    _msg info "Criando a partição /root com ${ROOT_SIZE}MB."
    parted $HD mkpart primary ext4 "${root_start}MiB" "${root_end}MiB" 2> /dev/null || err=1

    _msg info 'Criando a partição /home com o restante do HD.'
    parted $HD mkpart primary ext4 "${home_start}MiB" "$home_end" 2> /dev/null || err=1

    if [[ $err -eq 1 ]]; then
        _msg erro "Ocorreu um erro ao tentar particionar o HD."
        exit 1
    fi

}

function formatar_particao() {
    local err=0

    echo
    _msg info 'Formatando a partição /boot.'
    mkfs.vfat -F32 "${HD}1" -n BOOT 1> /dev/null || err=1

    _msg info 'Formatando a partição swap.'
    mkswap "${HD}2" 1> /dev/null || err=1

    _msg info 'Formatando a partição /root.'
    mkfs.ext4 "${HD}3" -L ROOT &> /dev/null || err=1

    _msg info 'Formatando a partição /home.'
    mkfs.ext4 "${HD}4" -L HOME &> /dev/null || err=1

    if [[ $err -eq 1 ]]; then
        _msg erro "Ocorreu um erro ao tentar formatar as partições."
        exit 1
    fi

}

function montar_particao() {
    local err=0

    echo
    _msg info 'Montando a partição swap.'
    swapon "${HD}2" 1> /dev/null || err=1

    _msg info 'Montando a partição /root.'
    mount "${HD}3" /mnt 1> /dev/null || err=1

    _msg info 'Montando a partição /boot.'
    mkdir -p /mnt/boot
    mount "${HD}1" /mnt/boot 1> /dev/null || err=1

    _msg info 'Montando a partição /home.'
    mkdir /mnt/home
    mount "${HD}4" /mnt/home 1> /dev/null || err=1

    echo
    echo -e "================= ${AZUL}TABELA${SEMCOR} ================="
    lsblk "$HD"

    if [[ $err -eq 1 ]]; then
        _msg erro "Ocorreu um erro ao tentar montar as partições."
        exit 1
    fi

}

function instalar_sistema() {
    local err=0

    echo
    echo -n 'Instalando o sistema base.'
    (pacstrap /mnt base base-devel &> /dev/null) & spinner $! 

    _msg info "Gerando o fstab."
    genfstab -p -L /mnt >> /mnt/etc/fstab

    if [[ $err -eq 1 ]]; then
        _msg erro "Ocorreu um erro ao tentar instalar o sistema."
        exit 1
    fi
}

function configurar_sistema() {

    echo
    _msg info 'Entrando no novo sistema.'

    _msg info 'Configurando o teclado e o idioma para pt_BR.'
    _chroot "echo -e KEYMAP=br-abnt2\\nFONT=Lat2-Terminus16\\nFONT_MAP= > /etc/vconsole.conf"
    _chroot "sed -i '/pt_BR/,+1 s/^#//' /etc/locale.gen"
    _chroot "locale-gen" 1> /dev/null
    _chroot "echo LANG=pt_BR.UTF-8 > /etc/locale.conf"
    _chroot "export LANG=pt_BR.UTF-8"

    # Hora
    _msg info "Configurando o horário para a região ${TIMEZONE}."
    _chroot "ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime"
    _chroot "hwclock -w -u"
    _chroot "echo -e \"$NTP\" >> /etc/systemd/timesyncd.conf"

    # Multilib
    _msg info 'Habilitando o repositório multilib.'
    _chroot "sed -i '/multilib\]/,+1  s/^#//' /etc/pacman.conf"

    _msg info 'Sincronizando repositório.'
    _chroot "pacman -Sy" 1> /dev/null

    _msg info 'Populando as chaves dos respositórios.'
    _chroot "pacman-key --init && pacman-key --populate archlinux" &> /dev/null

    # Rede
    _msg info "Configurando o nome da maquina para: $HOST."
    _chroot "echo $HOST > /etc/hostname"

    _msg info 'Instalando e habilitando o NetworkManager.'
    _chroot 'pacman -S networkmanager --needed --noconfirm' 1> /dev/null
    _chroot "systemctl enable NetworkManager" 2> /dev/null

    # Usuario
    _msg info "Criando o usuário ${NEGRITO}$USER_NAME${SEMCOR}."
    _chroot "useradd -m -g users -G wheel -c \"$USER_NAME\" -s /bin/bash $MY_USER"

    _msg info "Adicionando o usuario: ${NEGRITO}$USER_NAME${SEMCOR} ao grupo sudoers."
    _chroot "sed -i '/%wheel ALL=(ALL) ALL/s/^#//' /etc/sudoers"

    _msg info "Definindo a senha do usuário ${NEGRITO}$USER_NAME${SEMCOR}."
    _chroot "echo ${MY_USER}:${MY_USER} | chpasswd"

    _msg info "Definindo a senha do usuário ${NEGRITO}Root${SEMCOR}."
    _chroot "echo root:${ROOT_PASSWD} | chpasswd"

    # Bootloader
    _msg info 'Instalando o bootloader.'
    _chroot "bootctl install" 2> /dev/null
    _chroot "echo -e \"$LOADER_CONF\" > /boot/loader/loader.conf"
    _chroot "echo -e \"$ARCH_ENTRIE\" > /boot/loader/entries/arch.conf"

    echo
    _msg info 'Sistema instalado com sucesso!'
    _msg info 'Retire a midia do computador e reincie a maquina!'
}

# Chamada das Funções
clear
bem_vindo
iniciar
particionar_hd
formatar_particao
montar_particao
instalar_sistema
configurar_sistema