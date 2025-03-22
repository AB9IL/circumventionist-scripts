#!/bin/bash

# Copyright (c) 2023 by Philip Collier, <webmaster@mofolinux.com>
# This script is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version. There is NO warranty; not even for
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

# Run this script as root (use sudo).

Encoding=UTF-8

startopenvpn(){
[[ "$(pgrep openvpn)" ]] && killall openvpn
fd -a -d 3 -t file -e ovpn . | \
rofi -dmenu -p "Select an *.ovpn File" | \
xargs -I{} openvpn --config "{}"
}

vpngate(){
killall openvpn
sh -c "menu-vpngate"
}

stopopenvpn(){
[[ "$(pgrep openvpn)" ]] && killall openvpn
exit
}

OPTIONS="Start OpenVPN (Config File)
Switch to VPN Gate
Stop OpenVPN"

# Take the choice; exit if no answer matches options.
REPLY="$(echo -e "$OPTIONS" | rofi \
    -dmenu -p "OpenVPN - Select Action" \
    -l 3 \
    -mesg "Manage OpenVPN connections.")"

[[ -z "$REPLY" ]] && echo "something went wrong" && exit 1
[[  "$REPLY" == "Start OpenVPN (Config File)" ]] && startopenvpn
[[  "$REPLY" == "Switch to VPN Gate" ]] && vpngate
[[  "$REPLY" == "Stop OpenVPN" ]] && stopopenvpn
