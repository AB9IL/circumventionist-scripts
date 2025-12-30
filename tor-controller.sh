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
sleep 4
systemctl start tor.service
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
sleep 4
systemctl start tor.service
}

torproxychains(){
echo 'socks5://127.0.0.1:9050' > /tmp/session_proxy
touch /tmp/proxyflag
sudo sed -i 's/^### FZPROXY.*/### FZPROXY\nsocks5 127.0.0.1 9050/;
    /### FZPROXY\nsocks5 127.0.0.1 9050/q' /etc/proxychains4.conf
systemctl enable tor.service
sleep 4
systemctl start tor.service
}

remote_tor(){
echo 'socks5://127.0.0.1:9050' > /tmp/session_proxy
$TERMINAL -e "tor-remote" &
# wait for user to make a choice
while ! [[ -f "/tmp/proxyflag" ]]; do
    sleep 1
done
}

torstop(){
rm /tmp/proxyflag
# force restoration for basic Tor in case other proxies were set
sudo sed -i 's/^### FZPROXY.*/### FZPROXY\nsocks5 127.0.0.1 9050/;
    /### FZPROXY\nsocks5 127.0.0.1 9050/q' /etc/proxychains4.conf
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
systemctl stop tor.service
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

Usage: $0 <option>
Options:    --gui     Graphical user interface.
            --help  This help screen.\n"
}

# index of commands
ROFI_COMMAND1='rofi \
    -dmenu -p Select \
    -l 6 \
    -mesg "Manage Local Tor connections.  You should
consider running Tor on a remote server,
then VPN or SSH or Proxy into that server."'

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

OPTIONS="Tor-Remote to a distant server
Start Tor and use Obfs4 or Scramblesuit
Start Tor and use Proxychains
Start Tor and use Snowflake
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
[[ "$REPLY" == "Tor-Remote to a distant server" ]] && remote_tor
[[ "$REPLY" == "Update Proxy List" ]] && update_proxylist
[[ "$REPLY" == "Stop Tor" ]] && torstop
