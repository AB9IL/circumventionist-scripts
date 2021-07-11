#!/bin/bash

# Copyright (c) 2021 by Philip Collier, <webmaster@mofolinux.com>
# This script is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version. There is NO warranty; not even for
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Encoding=UTF-8

startopenvpn(){
sudo killall openvpn
file=$(zenity --file-selection --title="Select an *.ovpn File" --filename=$HOME/openvpn/)
sudo x-termiinal-emulator -e "sh -c 'openvpn --config $file'"&
}

vpngate(){
sudo killall openvpn
sh -c "menu-vpngate"
}

stopopenvpn(){
sudo killall openvpn
exit
}

OPTIONS="Start OpenVPN (Config File)
Switch to VPN Gate
Stop OpenVPN"

# Take the choice; exit if no answer matches options.
REPLY="$(echo -e "$OPTIONS" | rofi \
    -dmenu -p "OpenVPN - Select Action" \
    -lines 3 \
    -mesg "Manage OpenVPN connections.")"

[[ -z "$REPLY" ]] && echo "something went wrong" && exit 1
[[  "$REPLY" == "Start OpenVPN (Config File)" ]] && startopenvpn
[[  "$REPLY" == "Switch to VPN Gate" ]] && vpngate
[[  "$REPLY" == "Stop OpenVPN" ]] && stopopenvpn
