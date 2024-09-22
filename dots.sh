#!/bin/bash

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# bin
ln -s ${BASEDIR}/bin $HOME/bin

# fontconfig
ln -s ${BASEDIR}/fontconfig $HOME/.config/fontconfig

# kitty
ln -s ${BASEDIR}/kitty $HOME/.config/kitty

# mako
ln -s ${BASEDIR}/mako $HOME/.config/mako

# mpd
ln -s ${BASEDIR}/mpd $HOME/.mpd

# mplayer
ln -s ${BASEDIR}/mplayer $HOME/.mplayer

# msmtp
ln -s ${BASEDIR}/msmtprc $HOME/.msmtprc

# multitail
ln -s ${BASEDIR}/multitailrc $HOME/.multitailrc

# mutt
ln -s ${BASEDIR}/mutt $HOME/.mutt

# ncmpcpp
ln -s ${BASEDIR}/ncmpcpp $HOME/.ncmpcpp

# neofetch
ln -s ${BASEDIR}/neofetch $HOME/.config/neofetch

# offlineimap
ln -s ${BASEDIR}/offlineimap.py $HOME/.offlineimap.py
ln -s ${BASEDIR}/offlineimaprc $HOME/.offlineimaprc

# ranger
ln -s ${BASEDIR}/ranger $HOME/.config/ranger

# startpage
ln -s ${BASEDIR}/startpage $HOME/.startpage

# todo
ln -s ${BASEDIR}/todo $HOME/.todo

# urlview
ln -s ${BASEDIR}/urlview $HOME/.urlview

# vim
ln -s ${BASEDIR}/vim $HOME/.vim
ln -s ${BASEDIR}/vimrc $HOME/.vimrc

# Sway stuff
ln -s ${BASEDIR}/sway $HOME/.config/sway
ln -s ${BASEDIR}/swaylock $HOME/.config/swaylock
ln -s ${BASEDIR}/swayshot.sh $HOME/.config/swayshot.sh
ln -s ${BASEDIR}/waybar $HOME/.config/waybar
ln -s ${BASEDIr}/wofi $HOME/.config/wofi

# zsh
ln -s ${BASEDIR}/zsh/zprofile $HOME/.zprofile
ln -s ${BASEDIR}/zsh/zsh_history $HOME/.zhistory
ln -s ${BASEDIR}/zsh/zshenv $HOME/.zshenv
ln -s ${BASEDIR}/zsh/zshrc $HOME/.zshrc
