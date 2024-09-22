#!/bin/sh
# call this script in button/power function of /etc/acpi/default.sh

OPTIONS="\ue1f6 lock\n
         \uf186 suspend\n
         \uf2f5 logout\n
         \ueab8 shutdown\n
         \uf2f1 reboot\n"

SELECTED=$(echo -e $OPTIONS |
           wofi -H 260 -d -p "power menu:" |
           awk '{print tolower($2)}')

case $SELECTED in
  lock)
    swaylock;;
  suspend)
    lock && systemctl suspend;;
  logout) 
    swaymsg exit;;
  shutdown)
    systemctl poweroff;;
  reboot)
    systemctl reboot;;
esac
