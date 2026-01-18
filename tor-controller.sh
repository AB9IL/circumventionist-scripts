#!/bin/bash

# Copyright (c) 2021 by Philip Collier, github.com/AB9IL
# This script is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version. There is NO warranty; not even for
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

# The file /tmp/session_proxy is used as a work-around because proxychains
# is FUBAR when using browsers based on Chrome.

Encoding=UTF-8

# terminal command
TERMINAL="x-terminal-emulator"

# ssh config file format: standard openssh config syntax.  Use the
# actual file ~/.ssh/config or a different one in the same format.
# Note: this script assumes key based ssh credentials.
CONFIGFILE="$HOME/.ssh/config"

# commandline arguments for Firefox and similar Gecko based browsers
ARGS_1=(--proxy socks5:127.0.0.1:9050 --new-window)

# commandline arguments for Brave, Chromium, Vivaldi, and similar browsers
# chromium parameters from:
# https://github.com/eyedeekay/I2P-Configuration-For-Chromium
CHROMIUM_I2P="$HOME/.config/tor/chromium"
[ -d "$CHROMIUM_I2P" ] || mkdir -p "$CHROMIUM_I2P"

ARGS_2=(--user-data-dir="$CHROMIUM_I2P" \
    --proxy-server="socks5://127.0.0.1:9050" \
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
    --new-window)

# define the web browser (brave-browser, brave-browser-beta, firefox, vivaldi,
# chromium, x-www-browser)
#startbrowser="firefox"
startbrowser="vivaldi"

# Set the proper arguments for the browser
ARGS=${ARGS_2[*]}


################################################################################
#  BEWARE OF DRAGONS BELOW!!
################################################################################

torobfs4(){
echo 'socks5://127.0.0.1:9050' > /tmp/session_proxy
touch /tmp/proxyflag
sudo sed -i 's/^### FZPROXY.*/### FZPROXY\nsocks5 127.0.0.1 9050/;
    /### FZPROXY\nsocks5 127.0.0.1 9050/q' /etc/proxychains4.conf
export https_proxy=127.0.0.1:9050
export HTTPS_PROXY=127.0.0.1:9050
export http_proxy=127.0.0.1:9050
export HTTP_PROXY=127.0.0.1:9050
export socks_proxy=127.0.0.1:9050
export SOCKS_PROXY=127.0.0.1:9050
export NO_PROXY='localhost, 127.0.0.1'
export no_proxy='localhost, 127.0.0.1'
echo "UseBridges 1
ClientTransportPlugin obfs3,obfs4,scramblesuit exec /usr/bin/obfs4proxy managed
ClientTransportPlugin meek exec /usr/bin/meek-client
Bridge ${bridgedata}" | sudo tee /etc/torrc.d/10_bridges
systemctl enable tor.service
sleep 2
systemctl start tor.service
sleep 2
torbrowse
}

torsnowflake(){
echo 'socks5://127.0.0.1:9050' > /tmp/session_proxy
touch /tmp/proxyflag
sudo sed -i 's/^### FZPROXY.*/### FZPROXY\nsocks5 127.0.0.1 9050/;
    /### FZPROXY\nsocks5 127.0.0.1 9050/q' /etc/proxychains4.conf
export https_proxy=127.0.0.1:9050
export HTTPS_PROXY=127.0.0.1:9050
export http_proxy=127.0.0.1:9050
export HTTP_PROXY=127.0.0.1:9050
export socks_proxy=127.0.0.1:9050
export SOCKS_PROXY=127.0.0.1:9050
export NO_PROXY='localhost, 127.0.0.1'
export no_proxy='localhost, 127.0.0.1'
echo "UseBridges 1
ClientTransportPlugin snowflake exec /usr/bin/snowflake-client -url https://snowflake-broker.torproject.net/ -front www.google.com -ice stun:stun.l.google.com:19302,stun:stun.antisip.com:3478,stun:stun.bluesip.net:3478,stun:stun.dus.net:3478,stun:stun.epygi.com:3478,stun:stun.sonetel.com:3478,stun:stun.uls.co.za:3478,stun:stun.voipgate.com:3478,stun:stun.voys.nl:3478 -log /var/log/tor/snowflake-client.log
Bridge snowflake 192.0.2.3:80 2B280B23E1107BB62ABFC40DDCC8824814F80A72
Bridge snowflake 192.0.2.4:80 8838024498816A039FCBBAB14E6F40A0843051FA
" | sudo tee /etc/torrc.d/10_bridges
systemctl enable tor.service
sleep 2
systemctl start tor.service
sleep 2
torbrowse
}

torproxychains(){
echo 'socks5://127.0.0.1:9050' > /tmp/session_proxy
touch /tmp/proxyflag
sudo sed -i 's/^### FZPROXY.*/### FZPROXY\nsocks5 127.0.0.1 9050/;
    /### FZPROXY\nsocks5 127.0.0.1 9050/q' /etc/proxychains4.conf
systemctl enable tor.service
sleep 2
systemctl start tor.service
sleep 2
torbrowse
}

remote_tor(){
MENU="Connect Tor Remote
Edit your server data
Disconnect Tor Remote"

# Make a selection.
SELECTION="$(echo -e "$MENU" | $COMMAND2 )"

[[  "$SELECTION" == "Connect Tor Remote" ]] && start_remote_tor_connection
[[  "$SELECTION" == "Edit your server data" ]] && edit_data
[[  "$SELECTION" == "Disconnect Tor Remote" ]] && stop_remote_tor_connection
[[  -z "$SELECTION" ]] && exit 0
}

start_remote_tor_connection(){
    echo 'socks5://127.0.0.1:9050' > /tmp/session_proxy
    sudo sed -i 's/^### FZPROXY.*/### FZPROXY\nsocks5 127.0.0.1 9050/;
        /### FZPROXY\nsocks5 127.0.0.1 9050/q' /etc/proxychains4.conf
    export https_proxy="https://127.0.0.1:9050"
    export HTTPS_PROXY="https://127.0.0.1:9050"
    export http_proxy="http://127.0.0.1:9050"
    export HTTP_PROXY="http://127.0.0.1:9050"
    export socks4_proxy="http://127.0.0.1:9050"
    export SOCKS4_PROXY="http://127.0.0.1:9050"
    export socks5_proxy="http://127.0.0.1:9050"
    export SOCKS5_PROXY="http://127.0.0.1:9050"
    export NO_PROXY='localhost, 127.0.0.1'
    export no_proxy='localhost, 127.0.0.1'
    SERVER="$(grep -E '^Host \w' $CONFIGFILE | awk '{print $2}' | $COMMAND3 )"
    export SERVER
    [[ -z "$SERVER" ]] && echo "No selection..." && stop_tor_connection && exit 1
    notify-send "Connecting to Tor instance on $SERVER"
    # set the proxy flag if a choice is made
    [[ -z "$SERVER" ]] || (echo "$SERVER" > /tmp/proxyflag && \
        sh -c "while ! ssh -L 9050:127.0.0.1:9050 -t $SERVER; do sleep 4; done") &
    sleep 2
    torbrowse
}

stop_remote_tor_connection(){
    sudo sed -i 's/^### FZPROXY.*/### FZPROXY\nsocks5 127.0.0.1 9050/;
        /### FZPROXY\nsocks5 127.0.0.1 9050/q' /etc/proxychains4.conf
    export https_proxy=
    export HTTPS_PROXY=
    export http_proxy=
    export HTTP_PROXY=
    export socks4_proxy=
    export SOCKS4_PROXY=
    export socks5_proxy=
    export SOCKS5_PROXY=
    export NO_PROXY=
    export no_proxy=
    k="$(pgrep "ssh")"
    #read -r SERVER < /tmp/proxyflag
    [ -f "/tmp/proxyflag" ] && notify-send "Disconnecting from $(\cat /tmp/proxyflag)"
    for process in ${k[@]};do
        #sudo pkill -f "ssh -L 9050:127.0.0.1:9050 -t -t $SERVER"
        sudo killall -g ssh
    done
    [ -f "/tmp/proxyflag" ] && rm /tmp/proxyflag
    exit 0
}

torbrowse(){
    ${startbrowser} ${ARGS}
}

torstop(){
rm /tmp/proxyflag
# force restoration for basic Tor in case other proxies were set
sudo sed -i 's/^### FZPROXY.*/### FZPROXY\nsocks5 127.0.0.1 9050/;
    /### FZPROXY\nsocks5 127.0.0.1 9050/q' /etc/proxychains4.conf
>/tmp/session_proxy
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
systemctl stop tor.service
stop_remote_tor_connection
killall -9 proxychains*
}

update_proxylist(){
$TERMINAL -e sh -c "fzproxy --anonymity=\"elite\";" && \
    echo -e "socks5 127.0.0.1 9050" | \
    sudo tee -a /etc/proxychains4.conf
}

showhelp() {
    echo -e "\nTor connection manager.

Use Tor as a secure and anonymous socks5 proxy.

Note 1:  You may use proxychains or torsocks to wrap your internet-using
         apps. The proxy is on address 127.0.0.1:9050

Note 2:  Use tor-remote if tunneling vis ssh to a remote tor instance.

          - You MUST set up key based logins on the servers
            AND have Tor installed on the server.

          - Use proxychains to wrap your internet-using apps.
            (This is already set up for Firefox, Vivaldi, or
            Brave if using the <browser>-with-proxy script.)

Usage: $0 <option>
Options:    --gui     Graphical user interface.
            --help    This help screen.\n"
}

torrecycle(){
    systemctl stop tor.service
    sleep 2
    systemctl start tor.service
}

# index of commands
ROFI_COMMAND1='rofi -dmenu -p Select -l 8'
FZF_COMMAND1='fzf --layout=reverse'
ROFI_COMMAND2='rofi -dmenu -p Select -l 3'
FZF_COMMAND2='fzf --layout=reverse --header=Select:'
ROFI_COMMAND3='rofi -dmenu -p Select'
FZF_COMMAND3='fzf --layout=reverse --header=Select:'
FZF_COMMAND4="vim $CONFIGFILE"
ROFI_COMMAND4="x-terminal-emulator -e vim $CONFIGFILE"


case "$1" in
"")
    COMMAND1=$FZF_COMMAND1
    COMMAND2=$FZF_COMMAND2
    COMMAND3=$FZF_COMMAND3
    COMMAND4=$FZF_COMMAND4
    ;;
"--gui")
    COMMAND1=$ROFI_COMMAND1
    COMMAND2=$ROFI_COMMAND2
    COMMAND3=$ROFI_COMMAND3
    COMMAND4=$ROFI_COMMAND4
    ;;
*)
    showhelp
    ;;
esac

OPTIONS="Tor-Remote to a distant server
Start Tor and use Obfs4 or Scramblesuit
Start Tor and use Proxychains
Start Tor and use Snowflake
Recycle Tor Connection
Open Web Browser
Update Proxy List
Stop Tor"

# Take the choice; exit if no answer matches options.
REPLY="$(echo -e "$OPTIONS" | $COMMAND1)"
[[ -z "$REPLY" ]] && exit 1
[[  "$REPLY" == "Start Tor and use Obfs4 or Scramblesuit" ]] && \
        bridgedata=$(yad --width 350 --height 50 --forms \
            --title="Tor Pluggable Transport Configuration" \
            --no-buttons \
            --text='For Obfs4 or Scramblesuit bridges send
an email to bridges@torproject.org with
the text "get transport obfs4" or
"get transport scramblesuit" in the
message body.'  \
            --entry="Enter Pluggable Transport Data:") && torobfs4
[[ "$REPLY" == "Start Tor and use Proxychains" ]] && torproxychains
[[ "$REPLY" == "Start Tor and use Snowflake" ]] && torsnowflake
[[ "$REPLY" == "Recycle Tor Connection" ]] && torrecycle
[[ "$REPLY" == "Open Web Browser" ]] && torbrowse
[[ "$REPLY" == "Tor-Remote to a distant server" ]] && remote_tor
[[ "$REPLY" == "Update Proxy List" ]] && update_proxylist
[[ "$REPLY" == "Stop Tor" ]] && torstop
