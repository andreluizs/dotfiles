#!/bin/bash
#===============================================================================
#
#          FILE: install.sh
#
#         USAGE: ./install.sh
#
#   DESCRIPTION: Script para realizar a instalação do Arch Linux.
#
#        AUTHOR: André Luiz dos Santos (andreluizs@live.com),
#       CREATED: 03/2018
#      REVISION: 1.0.0b
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
MY_USER_PASSWD=${MY_USER_PASSWD:-'andre'}
ROOT_PASSWD=${ROOT_PASSWD:-'root'}

# HD
HD=${HD:-'/dev/sda'}

# Nome da maquina
HOST=${HOST:-"archlinux"}

# Tamanho das partições em MB
BOOT_SIZE=${BOOT_SIZE:-512}
SWAP_SIZE=${SWAP_SIZE:-4096}
ROOT_SIZE=${ROOT_SIZE:-51200}

# Configurações da Região
readonly KEYBOARD_LAYOUT="br abnt2"
readonly LANGUAGE="pt_BR"
readonly TIMEZONE="America/Sao_Paulo"
readonly NTP="NTP=0.arch.pool.ntp.org 1.arch.pool.ntp.org2.arch.pool.ntp.org 3.arch.pool.ntp.org
FallbackNTP=FallbackNTP=0.pool.ntp.org 1.pool.ntp.org 0.fr.pool.ntp.org"

# Entradas do Bootloader
#readonly LOADER_CONF="timeout 0\\ndefault arch"
#readonly ARCH_ENTRIE="title Arch Linux\\nlinux /vmlinuz-linux\\ninitrd /initramfs-linux.img\\noptions root=${HD}2 rw"
readonly ARCH_ENTRIE="'"Default Boot"' \"rw root=${HD}2\""

# Pacotes extras
readonly PKG_EXTRA="bash-completion xf86-input-libinput xdg-user-dirs 
network-manager-applet google-chrome spotify playerctl visual-studio-code-bin 
telegram-desktop p7zip zip unzip unrar brisk-menu-git ttf-iosevka-term-ss09 ttf-ubuntu-font-family mate-tweak compton 
lightdm-webkit2-greeter lightdm-webkit-theme-aether openbox obconf lxappearance ttf-ms-fonts nitrogen"

#===============================================================================
#----------------------------------FUNÇÕES--------------------------------------
#===============================================================================

function _msg() {
    case $1 in
    info)       echo -e "${VERDE}[I]${SEMCOR} $2" ;;
    erro)       echo -e "${VERMELHO}[X]${SEMCOR} $2" ;;
    quest)      echo -ne "${AZUL}[?]${SEMCOR} $2" ;;
    esac
}

function _chroot() {
    arch-chroot /mnt /bin/bash -c "$1"
}

function _chuser() {
    _chroot "su ${MY_USER} -c \"$1\""
}

function _spinner(){
    local pid=$2
    local i=1
    local param=$1
    local sp='/-\|'
    echo -ne "$param "
    while [ -d /proc/"${pid}" ]; do
        printf "${VERMELHO}[${SEMCOR}${AMARELO}%c${SEMCOR}${VERMELHO}]${SEMCOR}   " "${sp:i++%${#sp}:1}"
        sleep 0.75
        printf "\\b\\b\\b\\b\\b\\b"
    done
}

function _ler_info_usuario(){
    _msg quest 'Informe o nome completo do usuário: '
    read -re MY_USER_NAME
    MY_USER_NAME=${MY_USER_NAME:='André Luiz'}

    _msg quest 'Informe o nick do úsuario: '
    read -re MY_USER
    MY_USER=${MY_USER:='andre'}

    _msg quest "Informe o password para $MY_USER_NAME:\\n"
    read -rs MY_USER_PASSWD
    MY_USER_PASSWD=${MY_USER_PASSWD:='andre'}

    _msg quest "Informe o password para Root:\\n"
    read -rs ROOT_PASSWD
    ROOT_PASSWD=${ROOT_PASSWD:='root'}

    _msg quest "Informe o device em que o sistema será instalado (${HD}): "
    read -re HD
    HD=${HD:='/dev/sda'}

    _msg quest "Informe o nome da maquina: "
    read -re HOST
    HOST=${HOST:='archlinux'}
}



function bem_vindo() {
    echo -en "${NEGRITO}"
    echo -e "============================================================================"
    echo -e "              BEM VINDO AO INSTALADOR AUTOMÁTICO DO ARCH - UEFI             "
    echo -e "----------------------------------------------------------------------------"
    echo -e "                  André Luiz dos Santos (andreluizs@live.com)               "
    echo -e "                         Versão: 1.0.0b - Data: 03/2018                     "
    echo -e "----------------------------------------------------------------------------${SEMCOR}${MAGENTA}"
    echo -e "                  Esse instalador encontra-se em versão beta.              "
    echo -en "                 Usar esse instalador é por sua conta e risco.${SEMCOR}    "
}

function iniciar() {

    echo -e "${NEGRITO}"
    echo -e "================================= DEFAULT =================================="
    echo -e "Nome: ${MAGENTA}${MY_USER_NAME}${SEMCOR}            User: ${MAGENTA}${MY_USER}${SEMCOR}            Maquina: ${MAGENTA}${HOST}${SEMCOR}       "
    echo -e "Device: ${MAGENTA}${HD}${SEMCOR}   /boot: ${MAGENTA}${BOOT_SIZE}MB${SEMCOR}    /root: ${MAGENTA}${ROOT_SIZE}MB${SEMCOR}    /home: ${MAGENTA}restante do HD${SEMCOR}"
    echo -e "============================================================================"
    echo -en "${SEMCOR}"
    echo

    #_msg quest "Gostaria de realizar a instalação com as configurações DEFAULT? (${NEGRITO}S${SEMCOR}/n):"
    #read -r -e -n 1 padrao
    #padrao=${padrao:=s}

    #if [[ $padrao == "n" ]]; then
    #    _ler_info_usuario
    #else
    #    echo
        echo -e "${AMARELO}Vá tomar um café, eu cuido do resto!${SEMCOR}"
    #fi
    
    #echo
    _msg info 'Sincronizando a hora.'
    timedatectl set-ntp true

    _msg info "Definindo o teclado para: $KEYBOARD_LAYOUT."
    localectl set-x11-keymap "$KEYBOARD_LAYOUT"
    
    # ARRUMAR
    _msg info 'Procurando o servidor mais rápido.'
    pacman -Sy reflector --needed --noconfirm &> /dev/null
    reflector --country Brazil --verbose --latest 10 --sort rate --save /etc/pacman.d/mirrorlist 1> /dev/null
    # sed -n '/^## Brazil/ {n;p}' /etc/pacman.d/mirrorlist >/etc/pacman.d/mirrorlist.backup
    # rankmirrors -n 6 /etc/pacman.d/mirrorlist.backup >/etc/pacman.d/mirrorlist
}

function particionar_hd() {
    local err=0

    # Calculo para criar as partições com o parted
    local boot_start=1
    local boot_end=$((BOOT_SIZE + boot_start))
    local root_start=$boot_end
    local root_end=$((root_start + ROOT_SIZE))
    local home_start=$root_end
    local home_end="100%"

    _msg info "Definindo o device: ${HD} para GPT."
    parted -s "$HD" mklabel gpt &> /dev/null

    _msg info "Criando a partição /boot com ${MAGENTA}${BOOT_SIZE}MB${SEMCOR}."
    parted "$HD" mkpart ESP fat32 "${boot_start}MiB" "${boot_end}MiB" 2> /dev/null || err=1
    parted "$HD" set 1 boot on 2> /dev/null || err=1

    _msg info "Criando a partição /root com ${MAGENTA}${ROOT_SIZE}MB${SEMCOR}."
    parted "$HD" mkpart primary ext4 "${root_start}MiB" "${root_end}MiB" 2> /dev/null || err=1

    _msg info "Criando a partição /home com o ${MAGENTA}restante do HD${SEMCOR}."
    parted "$HD" mkpart primary ext4 "${home_start}MiB" "$home_end" 2> /dev/null || err=1

    if [[ $err -eq 1 ]]; then
        _msg erro "Ocorreu um erro ao tentar particionar o HD."
        exit 1
    fi

}

function formatar_particao() {
    local err=0

    _msg info 'Formatando a partição /boot.'
    mkfs.vfat -F32 "${HD}1" -n BOOT 1> /dev/null || err=1

    _msg info 'Formatando a partição /root.'
    mkfs.ext4 "${HD}2" -L ROOT &> /dev/null || err=1

    _msg info 'Formatando a partição /home.'
    mkfs.ext4 "${HD}3" -L HOME &> /dev/null || err=1

    if [[ $err -eq 1 ]]; then
        _msg erro "Ocorreu um erro ao tentar formatar as partições."
        exit 1
    fi

}

function montar_particao() {
    local err=0

    _msg info 'Montando a partição /root.'
    mount "${HD}2" /mnt 1> /dev/null || err=1

    _msg info 'Montando a partição /boot.'
    mkdir -p /mnt/boot/efi
    mount "${HD}1" /mnt/boot/efi 1> /dev/null || err=1

    _msg info 'Montando a partição /home.'
    mkdir /mnt/home
    mount "${HD}3" /mnt/home 1> /dev/null || err=1

    echo
    echo -e "${AZUL}================= TABELA =================${SEMCOR}"
    lsblk "$HD"

    if [[ $err -eq 1 ]]; then
        _msg erro "Ocorreu um erro ao tentar montar as partições."
        exit 1
    fi

}

function instalar_sistema() {
    local err=0

    echo
    (pacstrap /mnt base base-devel &> /dev/null) &
    _spinner "${VERDE}[I]${SEMCOR} Instalando o sistema base:" $! 
    echo -ne "${VERMELHO}[${SEMCOR}${VERDE}100%${SEMCOR}${VERMELHO}]${SEMCOR}\\n"

    _msg info "Gerando o fstab."
    genfstab -p -L /mnt >> /mnt/etc/fstab

    if [[ $err -eq 1 ]]; then
        _msg erro "Ocorreu um erro ao tentar instalar o sistema."
        exit 1
    fi
}

function configurar_sistema() {
    _msg info 'Entrando no novo sistema.'
    _msg info 'Configurando o teclado e o idioma para pt_BR.'
    _chroot "echo -e \"KEYMAP=br-abnt2\\nFONT=Lat2-Terminus16\\nFONT_MAP=\" > /etc/vconsole.conf"
    _chroot "sed -i '/pt_BR/,+1 s/^#//' /etc/locale.gen"
    _chroot "locale-gen" 1> /dev/null
    _chroot "echo LANG=pt_BR.UTF-8 > /etc/locale.conf"
    _chroot "export LANG=pt_BR.UTF-8"

    # Swapfile
    _msg info "Criando o swapfile com ${SWAP_SIZE}MB."
    _chroot "fallocate -l \"${SWAP_SIZE}M\" /swapfile" 1> /dev/null
    _chroot "chmod 600 /swapfile" 1> /dev/null
    _chroot "mkswap /swapfile" 1> /dev/null
    _chroot "swapon /swapfile" 1> /dev/null
    _chroot "echo -e /swapfile none swap defaults 0 0 >> /etc/fstab"

    # Hora
    _msg info "Configurando o horário para a região ${TIMEZONE}."
    _chroot "ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime"
    _chroot "hwclock --systohc --localtime"
    _chroot "echo -e \"$NTP\" >> /etc/systemd/timesyncd.conf"

    # Multilib
    _msg info 'Habilitando o repositório multilib.'
    _chroot "sed -i '/multilib\\]/,+1  s/^#//' /etc/pacman.conf"
    
    _msg info 'Adicionando o servidor mais rápido.'
     _chroot "pacman -Sy reflector --needed --noconfirm" &> /dev/null
     _chroot "reflector --country Brazil --verbose --latest 10 --sort rate --save /etc/pacman.d/mirrorlist" 1> /dev/null

    _msg info 'Populando as chaves dos respositórios.'
    _chroot "pacman-key --init && pacman-key --populate archlinux" &> /dev/null

    # Rede
    _msg info "Configurando o nome da maquina para: ${MAGENTA}$HOST${SEMCOR}."
    _chroot "echo \"$HOST\" > /etc/hostname"

    _msg info 'Instalando e habilitando o NetworkManager.'
    _chroot "pacman -S networkmanager --needed --noconfirm" 1> /dev/null
    _chroot "systemctl enable NetworkManager" 2> /dev/null

    # Usuario
    _msg info "Criando o usuário ${MAGENTA}$MY_USER_NAME${SEMCOR}."
    _chroot "useradd -m -g users -G wheel -c \"$MY_USER_NAME\" -s /bin/bash $MY_USER"

    _msg info "Adicionando o usuario: ${MAGENTA}$MY_USER${SEMCOR} ao grupo sudoers."
    _chroot "sed -i '/%wheel ALL=(ALL) NOPASSWD: ALL/s/^#//' /etc/sudoers"

    _msg info "Definindo a senha do usuário ${MAGENTA}$MY_USER_NAME${SEMCOR}."
    _chroot "echo ${MY_USER}:${MY_USER_PASSWD} | chpasswd"

    _msg info "Definindo a senha do usuário ${MAGENTA}Root${SEMCOR}."
    _chroot "echo root:${ROOT_PASSWD} | chpasswd"
   
    # Bootloader
    _msg info 'Instalando o bootloader.'
    #_chroot "bootctl install" 2> /dev/null
    #_chroot "echo -e \"$LOADER_CONF\" > /boot/loader/loader.conf"
    #_chroot "echo -e \"$ARCH_ENTRIE\" > /boot/loader/entries/arch.conf"
    _chroot "pacman -S refind-efi --needed --noconfirm" 1> /dev/null
    _chroot "refind-install --usedefault \"${HD}1\"" 1> /dev/null
    #_chroot "mkrlconf"
    _chroot "echo -e ${ARCH_ENTRIE} > /boot/refind_linux.conf"
    # Tempo de espera do boot
    #timeout 10

    # Menu Arch Linux
    # menuentry "Arch Linux" {
    # icon     /EFI/refind/icons/os_arch.png
    # volume   "Arch Linux"
    # loader   /boot/vmlinuz-linux
    # initrd   /boot/initramfs-linux.img
    # options  "root=/dev/sda2 rw add_efi_memmap"
    # submenuentry "Boot using fallback initramfs" {
        #initrd /boot/initramfs-linux-fallback.img
    #}
    # submenuentry "Boot to terminal" {
        # add_options "systemd.unit=multi-user.target"
    #}
    #disabled
    #}


    # Xorg
    _msg info 'Instalando o Display Server (X.org).'
    _chroot "pacman -S xorg-server xorg-xinit xorg-xprop xorg-xbacklight xorg-xdpyinfo xorg-xrandr --needed --noconfirm" &> /dev/null
    
    # Drive de video
    _msg info 'Instalando o Drive de Video (Intel).'
    _chroot "pacman -S intel-ucode mesa xf86-video-intel lib32-mesa vulkan-intel --needed --noconfirm" &> /dev/null
    #_chroot "pacman -S virtualbox-guest-utils virtualbox-guest-modules-arch --needed --noconfirm" 1> /dev/null
    #_chroot "systemctl enable vboxservice.service" &> /dev/null
    
    # DE
    (_chroot "pacman -S mate mate-power-manager engrampa mate-calc mozo mate-applets caja --needed --noconfirm" &> /dev/null) &
    _spinner "${VERDE}[I]${SEMCOR} Instalando o Desktop Environment (MATE):" $! 
    echo -ne "${VERMELHO}[${SEMCOR}${VERDE}100%${SEMCOR}${VERMELHO}]${SEMCOR}\\n"

    # Display Manager
    _msg info 'Instalando o Display Manager (LightDM).'
    _chroot "pacman -S lightdm --needed --noconfirm" &> /dev/null
    _chroot "systemctl enable lightdm.service" &> /dev/null

    # Drive de som
    _msg info 'Instalando o Som (alsa / pulseaudio).'
    _chroot "pacman -S alsa-utils pulseaudio --needed --noconfirm" &> /dev/null

    # AUR 
    _msg info 'Instalando o gerenciador de pacotes do AUR (Trizen).'
    _chroot "pacman -S git --needed --noconfirm" &> /dev/null
    _chuser "cd /home/${MY_USER} && git clone https://aur.archlinux.org/trizen.git && 
             cd /home/${MY_USER}/trizen && makepkg -si --noconfirm && 
             rm -Rf /home/${MY_USER}/trizen" &> /dev/null
             
    # Dotfiles do Github
    _msg info 'Clonando os dotfiles.'
    _chuser "https://github.com/andreluizs/dotfiles.git ." 1> /dev/null

    _msg info "Instalando pacotes extras"
    _chuser "trizen -S ${PKG_EXTRA} --needed --noconfirm" &> /dev/null
    _chuser "export LANG=pt_BR.UTF-8 && xdg-user-dirs-update" &> /dev/null
    
    _msg info 'Sistema instalado com sucesso!'
    _msg info 'Reinicie o computador'
    
    sleep 3 && umount -R /mnt
    # swpoff -L SWAP
    # reboot
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
