#!/bin/bash

# Copyright (c) 2021 by Philip Collier, github.com/AB9IL
# This script is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version. There is NO warranty; not even for
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# The file /tmp/session_proxy is used as a work-around because proxychains
# is FUBAR when using browsers based on Chrome.

Encoding=UTF-8

# terminal command
TERMINAL="x-terminal-emulator"

# commandline arguments for Firefox and similar Gecko based browsers
ARGS_1=(--proxy socks5:127.0.0.1:4444 --new-window "http://127.0.0.1:7070")

# commandline arguments for Brave, Chromium, Vivaldi, and similar browsers
# chromium parameters from:
# https://github.com/eyedeekay/I2P-Configuration-For-Chromium
CHROMIUM_I2P="$HOME/.config/i2p/chromium"
[ -d "$CHROMIUM_I2P" ] || mkdir -p "$CHROMIUM_I2P"

ARGS_2=(--user-data-dir="$CHROMIUM_I2P" \
    --proxy-server="socks5://127.0.0.1:4444" \
    --safebrowsing-disable-download-protection \
    --disable-client-side-phishing-detection \
    --disable-3d-apis \
    --disable-accelerated-2d-canvas \
    --disable-remote-fonts \
    --disable-sync-preferences \
    --disable-sync \
    --disable-speech \
    --disable-webgl \
    --disable-reading-from-canvas \
    --disable-gpu \
    --disable-auto-reload \
    --disable-background-networking \
    --disable-d3d11 \
    --disable-file-system "$@" \
    --proxy-bypass-list=127.0.0.1:7070 \
    --new-window "http://127.0.0.1:7070")

# define the web browser (brave-browser, brave-browser-beta, firefox, vivaldi,
# chromium, x-www-browser)
startbrowser="vivaldi"

# Set the proper arguments for the browser
ARGS=${ARGS_2[*]}


################################################################################
#  BEWARE OF DRAGONS BELOW!!
################################################################################

RAISE(){
    sudo sed -i 's/^### FZPROXY.*/### FZPROXY\nhttp 127.0.0.1 4444/' /etc/proxychains4.conf
    sudo systemctl start i2pd.service
     /usr/bin/i2prouter start
    echo 'http://127.0.0.1:4444' > /tmp/session_proxy
     i2pbrowse
}

DROP(){
    sudo systemctl stop i2pd.service
}

i2pbrowse(){
    ${startbrowser} ${ARGS}
}

i2pstart(){
touch /tmp/proxyflag
export https_proxy=127.0.0.1:4444
export HTTPS_PROXY=127.0.0.1:4444
export http_proxy=127.0.0.1:4444
export HTTP_PROXY=127.0.0.1:4444
#export socks_proxy=127.0.0.1:14444
#export SOCKS_PROXY=127.0.0.1:14444
export NO_PROXY='localhost, 127.0.0.1'
export no_proxy='localhost, 127.0.0.1'
RAISE &
}

i2pstop(){
rm /tmp/proxyflag
DROP
sudo sed -i '/^### FZPROXY.*/q' /etc/proxychains4.conf
> /tmp/session_proxy
export https_proxy=
export HTTPS_PROXY=
export http_proxy=
export HTTP_PROXY=
export socks_proxy=
export SOCKS_PROXY=
export NO_PROXY=
export no_proxy=
sed -i "
	s/http_proxy.*/http_proxy/g
	s/https_proxy.*/https_proxy/g
	s/no_proxy.*/no_proxy/g" ~/.w3m/config
exit
}

showhelp() {
    echo -e "\nI2P connection manager.

Use I2P to hidden services via garlic routing.

Note:  You may use proxychains to wrap your I2P-using
         apps. The proxy is on address 127.0.0.1:4444

Usage: $0 <option>
Options:    --gui   Graphical user interface.
            --help  This help screen.\n"
}

# index of commands
ROFI_COMMAND1=' rofi \
    -dmenu -p "Manage I2P" \
    -l 3'

FZF_COMMAND1='fzf --layout=reverse'

case "$1" in
"")
    COMMAND1=$FZF_COMMAND1
    ;;
"--gui")
    COMMAND1=$ROFI_COMMAND1
    ;;
*)
    showhelp
    ;;
esac

OPTIONS="Start I2P and configure proxy settings
Open web browser (I2P already running)
Stop I2P and restore proxy settings"

# Take the choice; exit if no answer matches options.
REPLY="$(echo -e "$OPTIONS" | $COMMAND1 )"

[[ -z "$REPLY" ]] && exit 1
[[  "$REPLY" == "Start I2P and configure proxy settings" ]] && i2pstart
[[  "$REPLY" == "Open web browser (I2P already running)" ]] && i2pbrowse
[[  "$REPLY" == "Stop I2P and restore proxy settings" ]] && i2pstop
