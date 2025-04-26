#!/bin/bash

# Copyright (c) 2024 by Philip Collier, github.com/AB9IL
# This script is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version. There is NO warranty; not even for
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

# The file /tmp/session_proxy is used as a work-around because proxychains
# is FUBAR when using browsers based on Chrome.

Encoding=UTF-8

# define the web browser
#startbrowser="forefox"
startbrowser="vivaldi"

setproxies(){
echo 'socks://127.0.0.1:1089' > /tmp/session_proxy
touch /tmp/proxyflag
sudo sed -i 's/^### FZPROXY.*/### FZPROXY\nsocks 127.0.0.1 1089/;' /etc/proxychains4.conf
export socks_proxy=127.0.0.1:1089
export SOCKS_PROXY=127.0.0.1:1089
export NO_PROXY='localhost, 127.0.0.1'
export no_proxy='localhost, 127.0.0.1'
sudo systemctl start v2ray
/opt/qv2ray/Qv2ray.AppImage
clearproxies
}

clearproxies(){
sudo systemctl stop v2ray
sleep 1
pkill qv2ray
rm /tmp/proxyflag
sudo sed -i '/^### FZPROXY.*/q' /etc/proxychains4.conf
> /tmp/session_proxy
export socks_proxy=
export SOCKS_PROXY=
export NO_PROXY=
export no_proxy=
}

OPTIONS="Use V2Ray / V2Mess Proxies
Stop V2Ray / V2Mess Proxies"

# Take the choice; exit if no answer matches options.
REPLY="$(echo -e "$OPTIONS" | rofi \
    -dmenu -p "Select Action" \
    -l 2 \
    -mesg "Manage V2Ray / V2Mess connections with QV2Ray application.")"

[[ -z "$REPLY" ]] && exit 1
[[ "$REPLY" == "Use V2Ray / V2Mess Proxies" ]] && setproxies
[[ "$REPLY" == "Stop V2Ray / V2Mess Proxies" ]] && clearproxies
