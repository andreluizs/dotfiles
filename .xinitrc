[[ -f ~/.Xresources ]] && xrdb -merge -I$HOME ~/.Xresources
export TERMINAL=termite
exec i3
