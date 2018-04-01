#!/usr/bin/env bash
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
MY_USER_NAME=${MY_USER_NAME:-'André Luiz dos Santos'}
MY_USER_PASSWD=${MY_USER_PASSWD:-'andre'}
ROOT_PASSWD=${ROOT_PASSWD:-'root'}

# HD
HD=${HD:-'/dev/sda'}

# Nome da maquina
HOST=${HOST:-"arch-note"}

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
readonly ARCH_ENTRIE="\\\"Default Boot\\\" \\\"rw root=${HD}2\\\""

# Video
readonly DISPLAY_SERVER="xorg-server xorg-xinit xorg-xprop xorg-xbacklight xorg-xdpyinfo xorg-xrandr"
readonly VGA_INTEL="intel-ucode mesa xf86-video-intel lib32-mesa vulkan-intel"
readonly VGA_VBOX="virtualbox-guest-utils virtualbox-guest-modules-arch"

# Pacotes extras
readonly PKG_EXTRA=("bash-completion" "xf86-input-libinput" "xdg-user-dirs" "vim"
                    "network-manager-applet" "google-chrome" "playerctl" "visual-studio-code-bin"
                    "telegram-desktop" "p7zip" "zip" "unzip" "unrar"
                    "ttf-iosevka-term-ss09" "ttf-ubuntu-font-family" "ttf-ms-fonts" "compton"
                    "jdk8" "intellij-idea-ultimate-edition" 
                    "pamac-aur-git" "adapta-gtk-theme" "hardcode-tray-git")

# Desktop Environment's
readonly DE_MATE="mate mate-power-manager engrampa mate-calc mozo mate-applets caja"
readonly DE_MATE_EXTRA="brisk-menu-git mate-tweak"
readonly DE_XFCE="xfce4 xfce4-goodies"
readonly DE_XFCE_EXTRA="file-roller"

# Window Manager's
#readonly WM_I3=
#readonly WM_I3_EXTRA=
readonly WM_OPENBOX="openbox obconf"
readonly WM_OPENBOX_EXTRA="nitrogen lxappearance termite"

# Display Manager
readonly DM="lightdm lightdm-webkit2-greeter"
# readonly DM_THEME=


#===============================================================================
#----------------------------------FUNÇÕES--------------------------------------
#===============================================================================

function _msg() {
    case $1 in
    info)       echo -e "${VERDE}[I]${SEMCOR} $2" ;;
    aten)       echo -e "${AMARELO}[A]${SEMCOR} $2" ;;
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
    echo -e "================================= DEFAULT ==================================${SEMCOR}"
    echo -e "Nome: ${MAGENTA}${MY_USER_NAME}${SEMCOR}            User: ${MAGENTA}${MY_USER}${SEMCOR}        Maquina: ${MAGENTA}${HOST}${SEMCOR}       "
    echo -e "Device: ${MAGENTA}${HD}${SEMCOR}   /boot: ${MAGENTA}${BOOT_SIZE}MB${SEMCOR}    /root: ${MAGENTA}${ROOT_SIZE}MB${SEMCOR}    /home: ${MAGENTA}restante do HD${SEMCOR}"
    echo -e "============================================================================"
    echo -en "${SEMCOR}"

    echo -e "${AMARELO}Começando a instalação automatica!${SEMCOR}"
    
    # Hora
    _msg info 'Sincronizando a hora.'
    timedatectl set-ntp true
    
    # Mirror
    _msg info 'Procurando o servidor mais rápido.'
    pacman -Sy reflector --needed --noconfirm &> /dev/null
    reflector --country Brazil --verbose --latest 10 --sort rate --save /etc/pacman.d/mirrorlist &> /dev/null
}

function particionar_hd() {

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
    parted "$HD" mkpart ESP fat32 "${boot_start}MiB" "${boot_end}MiB" 2> /dev/null
    parted "$HD" set 1 boot on 2> /dev/null

    _msg info "Criando a partição /root com ${MAGENTA}${ROOT_SIZE}MB${SEMCOR}."
    parted "$HD" mkpart primary ext4 "${root_start}MiB" "${root_end}MiB" 2> /dev/null

    _msg info "Criando a partição /home com o ${MAGENTA}restante do HD${SEMCOR}."
    parted "$HD" mkpart primary ext4 "${home_start}MiB" "$home_end" 2> /dev/null

}

function formatar_particao() {

    _msg info 'Formatando a partição /boot.'
    mkfs.vfat -F32 "${HD}1" -n BOOT 1> /dev/null

    _msg info 'Formatando a partição /root.'
    mkfs.ext4 "${HD}2" -L ROOT &> /dev/null

    _msg info 'Formatando a partição /home.'
    mkfs.ext4 "${HD}3" -L HOME &> /dev/null

}

function montar_particao() {

    _msg info 'Montando a partição /root.'
    mount "${HD}2" /mnt 1> /dev/null

    _msg info 'Montando a partição /boot.'
    mkdir -p /mnt/boot/efi
    mount "${HD}1" /mnt/boot/efi 1> /dev/null

    _msg info 'Montando a partição /home.'
    mkdir /mnt/home
    mount "${HD}3" /mnt/home 1> /dev/null

    echo -e "${AZUL}================= TABELA =================${SEMCOR}"
    lsblk "$HD"
    echo -e "${AZUL}==========================================${SEMCOR}"

}

function instalar_sistema() {

    (pacstrap /mnt base base-devel &> /dev/null) &
    _spinner "${VERDE}[I]${SEMCOR} Instalando o sistema base:" $! 
    echo -ne "${VERMELHO}[${SEMCOR}${VERDE}100%${SEMCOR}${VERMELHO}]${SEMCOR}\\n"

    _msg info "Gerando o fstab."
    genfstab -p -L /mnt >> /mnt/etc/fstab

}

function configurar_sistema() {
    _msg info "${NEGRITO}Entrando no novo sistema.${SEMCOR}"
    _msg info 'Configurando o teclado e o idioma para pt_BR.'
    _chroot "echo -e \"KEYMAP=br-abnt2\\nFONT=\\nFONT_MAP=\" > /etc/vconsole.conf"
    _chroot "sed -i '/pt_BR/,+1 s/^#//' /etc/locale.gen"
    _chroot "locale-gen" 1> /dev/null
    _chroot "echo LANG=pt_BR.UTF-8 > /etc/locale.conf"
    _chroot "export LANG=pt_BR.UTF-8"

    # Swapfile
    _msg info "Criando o swapfile com ${MAGENTA}${SWAP_SIZE}MB${SEMCOR}."
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
     _chroot "reflector --country Brazil --verbose --latest 10 --sort rate --save /etc/pacman.d/mirrorlist" &> /dev/null

    _msg info 'Populando as chaves dos respositórios.'
    _chroot "pacman-key --init && pacman-key --populate archlinux" &> /dev/null

    # Rede
    _msg info "Configurando o nome da maquina para: ${MAGENTA}$HOST${SEMCOR}."
    _chroot "echo \"$HOST\" > /etc/hostname"

    _msg info 'Instalando o NetworkManager.'
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
    _chroot "pacman -S refind-efi --needed --noconfirm" 1> /dev/null
    _chroot "refind-install --usedefault \"${HD}1\"" &> /dev/null
    _chroot "echo ${ARCH_ENTRIE} > /boot/refind_linux.conf" &> /dev/null

    # Xorg
    _msg info 'Instalando o display server.'
    _chroot "pacman -S ${DISPLAY_SERVER} --needed --noconfirm" &> /dev/null
    
    # Drive de video
    _msg info 'Instalando o drive de video.'
    #_chroot "pacman -S ${VGA_INTEL} --needed --noconfirm" &> /dev/null
    _chroot "pacman -S ${VGA_VBOX} --needed --noconfirm" 1> /dev/null

     # AUR 
    _msg info 'Instalando o gerenciador de pacotes do AUR.'
    _chroot "pacman -S git --needed --noconfirm" &> /dev/null
    _chuser "cd /home/${MY_USER} && git clone https://aur.archlinux.org/trizen.git && 
             cd /home/${MY_USER}/trizen && makepkg -si --noconfirm && 
             rm -rf /home/${MY_USER}/trizen" &> /dev/null
    _chroot "mount -o remount,size=10G,noatime /tmp"
    
    # DE
    (_chuser "trizen -S ${DE_XFCE} ${DE_XFCE_EXTRA} --needed --noconfirm" &> /dev/null) &
    _spinner "${VERDE}[I]${SEMCOR} Instalando o desktop environment:" $! 
    echo -ne "${VERMELHO}[${SEMCOR}${VERDE}100%${SEMCOR}${VERMELHO}]${SEMCOR}\\n"

    # WM
    _msg info 'Instalando o window manager.'
    _chuser "trizen -S ${WM_OPENBOX} ${WM_OPENBOX_EXTRA} --needed --noconfirm" &> /dev/null

    # Display Manager
    _msg info 'Instalando o display manager.'
    _chuser "trizen -S ${DM} --needed --noconfirm" &> /dev/null
    _chroot "sed -i '/^#greeter-session/c \greeter-session=lightdm-webkit2-greeter' /etc/lightdm/lightdm.conf"
    _chroot "systemctl enable lightdm.service" &> /dev/null

    # Drive de som
    _msg info 'Instalando as bibliotecas de audio.'
    _chroot "pacman -S alsa-utils alsa-oss alsa-lib pulseaudio --needed --noconfirm" &> /dev/null

    # Dotfiles do Github
    _msg info 'Clonando os dotfiles.'
    _chuser "cd /home/${MY_USER} && rm -rf .[^.] .??* &&
             git clone https://github.com/andreluizs/dotfiles.git ." &> /dev/null

    # Pacotes extras.
    (for i in "${PKG_EXTRA[@]}"; do
        _chuser "trizen -S ${i} --needed --noconfirm" &> /dev/null
    done) &
    _spinner "${VERDE}[I]${SEMCOR} Instalando os pacotes extras:" $! 
    echo -ne "${VERMELHO}[${SEMCOR}${VERDE}100%${SEMCOR}${VERMELHO}]${SEMCOR}\\n"
    _chuser "export LANG=pt_BR.UTF-8 && xdg-user-dirs-update"
    
    _msg info 'Sistema instalado com sucesso!'
    _msg aten 'Retire a midia do computador e logo em seguida reinicie a máquina.'
    umount -R /mnt &> /dev/null
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
