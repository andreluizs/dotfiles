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

# Dados pessoais.
USER="andre"
USER_NAME="André Luiz"
USER_PASSWD="andre"
ROOT_PASSWD="root"
HOST="arch-note"

# Dados do HD
HD=/dev/sda

# Tamanho das partições em MB
BOOT_SIZE=512
SWAP_SIZE=4096
ROOT_SIZE=30720
#HOME_SIZE=RESTO DO HD

BOOT_START=1
BOOT_END=$((BOOT_SIZE + BOOT_START))
SWAP_START=$BOOT_END
SWAP_END=$((SWAP_START + SWAP_SIZE))
ROOT_START=$SWAP_END
ROOT_END=$((ROOT_START + ROOT_SIZE))
HOME_START=$ROOT_END
HOME_END="100%"

# Configurações da Região
KEYBOARD_LAYOUT="br abnt2"
LANGUAGE="pt_BR"
TIMEZONE="America/Sao_Paulo"
NTP="NTP=0.arch.pool.ntp.org 1.arch.pool.ntp.org2.arch.pool.ntp.org 3.arch.pool.ntp.org\\nFallbackNTP=FallbackNTP=0.pool.ntp.org 1.pool.ntp.org 0.fr.pool.ntp.org"

LOADER_CONF="timeout 2\\ndefault arch"
ARCH_ENTRIE="title Arch Linux\\nlinux /vmlinuz-linux\\ninitrd /initramfs-linux.img\\noptions root=${HD}3 rw"

# Funções
msg_info() {
    echo "[INFO] $1"
}

msg_erro() {
    echo "[ERRO] $1"
}

iniciar() {
    local ERR=0

    msg_info 'Sincronizando a hora.'
    timedatectl set-ntp true

    msg_info "Definindo o teclado para: $KEYBOARD_LAYOUT."
    localectl set-x11-keymap "$KEYBOARD_LAYOUT"

    msg_info 'Procurando o servidor mais rápido.'
    sed -n '/^## Brazil/ {n;p}' /etc/pacman.d/mirrorlist >/etc/pacman.d/mirrorlist.backup
    rankmirrors -n 6 /etc/pacman.d/mirrorlist.backup >/etc/pacman.d/mirrorlist
}

particionar_hd() {
    local ERR=0

    msg_info 'Definindo a tabela de partição para GPT.'
    parted -s $HD mklabel gpt &>/dev/null

    msg_info "Criando a partição /boot com ${BOOT_SIZE}MB."
    parted $HD mkpart ESP fat32 "${BOOT_START}MiB" "${BOOT_END}MiB" 2>/dev/null  || ERR=1
    parted $HD set 1 boot on 2>/dev/null  || ERR=1

    msg_info "Criando a partição swap com ${SWAP_SIZE}MB."
    parted $HD mkpart primary linux-swap "${SWAP_START}MiB" "${SWAP_END}MiB" 2>/dev/null  || ERR=1

    msg_info "Criando a partição /root com ${ROOT_SIZE}MB."
    parted $HD mkpart primary ext4 "${ROOT_START}MiB" "${ROOT_END}MiB" 2>/dev/null  || ERR=1

    msg_info 'Criando a partição /home com o restante do HD.'
    parted $HD mkpart primary ext4 "${HOME_START}MiB" "$HOME_END" 2>/dev/null  || ERR=1

    if [[ $ERR -eq 1 ]]; then
        msg_erro "Ocorreu um erro ao tentar particionar o HD."
        exit 1
    fi

}

formatar_particao() {
    local ERR=0

    msg_info 'Formatando a partição /boot.'
    mkfs.vfat -F32 "${HD}1" -n BOOT 1>/dev/null  || ERR=1

    msg_info 'Formatando a partição swap.'
    mkswap "${HD}2" 1>/dev/null  || ERR=1

    msg_info 'Formatando a partição /root.'
    mkfs.ext4 "${HD}3" -L ROOT &>/dev/null  || ERR=1

    msg_info 'Formatando a partição /home.'
    mkfs.ext4 "${HD}4" -L HOME &>/dev/null  || ERR=1

    if [[ $ERR -eq 1 ]]; then
        msg_erro "Ocorreu um erro ao tentar formatar as partições."
        exit 1
    fi

}

montar_particao() {
    local ERR=0

    msg_info 'Montando a partição swap.'
    swapon "${HD}2" 1>/dev/null  || ERR=1

    msg_info 'Montando a partição /root.'
    mount "${HD}3" /mnt 1>/dev/null  || ERR=1

    msg_info 'Montando a partição /boot.'
    mkdir -p /mnt/boot
    mount "${HD}1" /mnt/boot 1>/dev/null  || ERR=1

    msg_info 'Montando a partição /home.'
    mkdir /mnt/home
    mount "${HD}4" /mnt/home 1>/dev/null  || ERR=1

    echo
    echo "---------------- TABELA ------------------"
    lsblk "$HD"

    if [[ $ERR -eq 1 ]]; then
        msg_erro "Ocorreu um erro ao tentar montar as partições."
        exit 1
    fi

}

instalar_sistema() {
    local ERR=0

    msg_info "Instalando o sistema base."
    pacstrap /mnt base base-devel &> /dev/null || ERR=1

    msg_info "Gerando o fstab."
    genfstab -p -L /mnt >> /mnt/etc/fstab

    if [[ $ERR -eq 1 ]]; then
        msg_erro "Ocorreu um erro ao tentar instalar o sistema."
        exit 1
    fi
}

function run_on_chroot() {
    arch-chroot /mnt /bin/bash -c "$1"
}

configurar_sistema() {

    echo
    echo '[-#-] CONFIGURANDO O NOVO SISTEMA'

    # Teclado e Idioma
    run_on_chroot "echo -e \"KEYMAP=br-abnt2\\nFONT=Lat2-Terminus16\\nFONT_MAP=\" >/etc/vconsole.conf"
    run_on_chroot "sed -i '/pt_BR/,+1 s/^#//' /etc/locale.gen"
    run_on_chroot "locale-gen"
    run_on_chroot "echo LANG=pt_BR.UTF-8 >/etc/locale.conf"
    run_on_chroot "export LANG=pt_BR.UTF-8"

    # Hora
    run_on_chroot "ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime"
    run_on_chroot "hwclock -w -u"
    run_on_chroot "echo -e \"$NTP\" >> /etc/systemd/timesyncd.conf"

    # Multilib
    run_on_chroot "sed -i '/multilib\]/,+1  s/^#//' /etc/pacman.conf"
    run_on_chroot "pacman -Sy"
    run_on_chroot "pacman-key --init && pacman-key --populate archlinux"

    # Rede
    run_on_chroot "echo $HOST >/etc/hostname"
    run_on_chroot "pacman -S networkmanager --needed --noconfirm"
    run_on_chroot "systemctl enable NetworkManager"

    # Usuario
    run_on_chroot "useradd -m -g users -G wheel -c \"$USER_NAME\" -s /bin/bash \"$USER\""
    run_on_chroot "sed -i '/%wheel ALL=(ALL) ALL/s/^#//' /etc/sudoers"
    run_on_chroot "echo \"${USER}:${USER_PASSWD}\" | chpasswd"
    run_on_chroot "echo \"root:${ROOT_PASSWD}\" | chpasswd"

    # Bootloader
    run_on_chroot "bootctl install"
    run_on_chroot "echo -e \"$LOADER_CONF\" > /boot/loader/loader.conf"
    run_on_chroot "echo -e \"$ARCH_ENTRIE\" > /boot/loader/entries/arch.conf"

    echo
    echo '[-#-] FIM'
}

# Chamada das Funções
clear
iniciar
particionar_hd
formatar_particao
montar_particao
instalar_sistema
configurar_sistema
