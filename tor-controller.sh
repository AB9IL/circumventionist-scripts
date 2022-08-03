#!/bin/bash

# Copyright (c) 2021 by Philip Collier, github.com/AB9IL
# This script is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version. There is NO warranty; not even for
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Encoding=UTF-8

torobfs4(){
export https_proxy=127.0.0.1:9050
export HTTPS_PROXY=127.0.0.1:9050
export http_proxy=127.0.0.1:9050
export HTTP_PROXY=127.0.0.1:9050
export socks_proxy=127.0.0.1:9050
export SOCKS_PROXY=127.0.0.1:9050
export NO_PROXY='localhost, 127.0.0.1'
export no_proxy='localhost, 127.0.0.1'
echo 'UseBridges 1
ClientTransportPlugin obfs3,obfs4,scramblesuit exec /usr/bin/obfs4proxy managed
ClientTransportPlugin meek exec /usr/bin/meek-client
Bridge ${bridgedata}' > /etc/torrc.d/10_bridges
source torsocks on
systemctl enable tor.service
sleep 4
systemctl start tor.service
sleep 4
torsocks x-www-browser --new-window "https://check.torproject.org" &
}

torproxychains(){
touch /tmp/proxyflag
systemctl enable tor.service
sleep 4
systemctl start tor.service
sleep 4
proxychains4 x-www-browser --new-window "https://check.torproject.org" &
}

remote_proxychains(){

x-terminal-emulator -e "tor-remote" &
sleep 4
x-www-browser --proxy-server="socks5://127.0.0.1:9050" --new-window "https://check.torproject.org" &
}

torstop(){
rm /tmp/proxyflag
sudo sed -i '/^### FZPROXY.*/q' /etc/proxychains4.conf
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
source torsocks off
systemctl stop tor.service
killall -9 proxychains*
}

update_proxylist(){
x-terminal-emulator -e sh -c "fzproxy --anonymity=\"elite\";" && \
    echo -e "socks4 127.0.0.1 9050\nsocks5 127.0.0.1 9050" | \
    sudo tee -a /etc/proxychains4.conf
}

OPTIONS="Start Tor and use Obfs4 or Scramblesuit
Start Tor and use Proxychains
Tor-Remote to a distant server
Update Proxy List
Stop Tor"

# Take the choice; exit if no answer matches options.
REPLY="$(echo -e "$OPTIONS" | rofi \
    -dmenu -p "Tor - Select Action" \
    -lines 5 \
    -mesg "Manage Local Tor connections.  You should
consider running Tor on a remote server,
then VPN or SSH or Proxy into that server.")"

[[ -z "$REPLY" ]] && exit 1
[[  "$REPLY" == "Start Tor and use Obfs4 or Scramblesuit" ]] && \
        bridgedata=$(zenity --width 350 --height 50 --forms \
            --title="Tor Pluggable Transport Configuration" \
            --text="For Obfs4 or Scramblesuit bridges send an email to: bridges@torproject.org \n
                    and either the text \"get transport obfs4\" or \"get transport scramblesuit\""  \
            --add-entry="Enter Pluggable Transport Data:") && \
		torobfs4
[[ "$REPLY" == "Start Tor and use Proxychains" ]] && torproxychains
[[ "$REPLY" == "Tor-Remote to a distant server" ]] && remote_proxychains
[[ "$REPLY" == "Update Proxy List" ]] && update_proxylist
[[ "$REPLY" == "Stop Tor" ]] && torstop
