#!/usr/bin/env sh
#
# Script para criar screencasts(vídeos da captura de tela) usando o ffmpeg.
#
# Desenvolvido por Lucas Saliés Brum <lucas@archlinux.com.br>
#
# Criado em: 09/06/2017 23:26:41
# Última Atualização: 16/01/2018 01:20:47

preset="ultrafast"
cor1="689d6a"
cor2="aa5448"
lixeira="${HOME}/.local/share/Trash"
icone="/usr/share/icons/Papirus-Adapta-Nokto/32x32/status/user-thrash.svg"

resolucao=$(xrandr | grep '*' | awk 'NR==1{print $1}')
audio=$(pacmd list-sinks | grep -A 1 'index: 0' | awk 'NR==2{print $2}' | awk '{print substr($0,2,length($0)-2)}') # list-sources, list-sinks

if [ -f ~/.config/user-dirs.dirs ]; then
    source ~/.config/user-dirs.dirs
    caminho="${XDG_VIDEOS_DIR}/Screencast/"
else
    caminho="${HOME}/Vídeo/Screencast/"
fi

if [ ! $1 ]; then
    data=$(date +%Y-%m-%d_%H-%M-%S)
    arquivo="${caminho}/screencast-${data}.mp4"
    [ ! -d $caminho ] && mkdir -p $caminho
fi

if pgrep -x "ffmpeg" > /dev/null
then
    [ "$(pgrep -x polybar)" ] && [ "$1" == "status" ] && echo "%{F#${cor2}}%{F-}" && exit
    if [ ! $1 ]; then
        killall ffmpeg
        notify-send -i $icone "ScreenCast" "Vídeo terminado."
        exit 0
    fi
else
    [ "$(pgrep -x polybar)" ] && [ "$1" == "status" ] && echo "%{F#${cor1}}%{F-}" && exit
    if [ ! "$1" ]; then
        notify-send -i $icone "ScreenCast" "Vídeo iniciado..."

        ffmpeg -f x11grab -s $resolucao -i :0 -f pulse -ac 2 -i default -c:v libx264 -crf 23 -profile:v baseline -level 3.0 -pix_fmt yuv420p -c:a aac -ac 2 -strict experimental -b:a 128k -movflags faststart $arquivo

    elif [ "$1" == "clear" ]; then
        icone="/usr/share/icons/Papirus-Adapta-Nokto/32x32/devices/computer-laptop.svg"
        listagem=(${caminho}*)
        if [ ${#listagem[@]} -gt 1 ]; then
            mv ${caminho}* ${lixeira}/files/
            notify-send -i $icone "ScreenCast" "Pasta de screencasts limpa!"
        else
            notify-send -i $icone "ScreenCast" "Pasta de screencasts já está limpa!"
        fi
        exit 0
    fi
fi

exit 0