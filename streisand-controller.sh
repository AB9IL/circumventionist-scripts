#!/bin/bash

# Copyright (c) 2021 by Philip Collier, <webmaster@mofolinux.com>
# This script is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version. There is NO warranty; not even for
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

check_dependencies(){
x-terminal-emulator -e 'sh -c  "cd /opt/streisand/ && ./util/venv-dependencies.sh ./venv && read line"'
}

createkeys(){
x-terminal-emulator -e 'sh -c  "ssh-keygen && read line"'
}

runstreisand(){
source "/opt/streisand/env/bin/activate"
x-terminal-emulator -e 'sh -c  "cd /opt/streisand/ && ./streisand && read line"'
}

getout(){
deactivate
exit
}

OPTIONS="Run Streisand
Check Dependencies
Create an SSH key pair
Stop Streisand"

# Take the choice; exit if no answer matches options.
REPLY="$(echo -e "$OPTIONS" | rofi \
    -lines 4 \
    -dmenu -p "OpenVPN - Select Action" \
    -mesg "Set up and run a VPN on your own server.
Note: You should backup your SSH keys and server 
credentials to a safe place off of this system.
See the README files in /opt/streisand for more
information.")"

[[  "$REPLY" == "Run Streisand" ]] && runstreisand
[[  "$REPLY" == "Check Dependencies" ]] && check_dependencies
[[  "$REPLY" == "Create an SSH key pair" ]] && createkeys
[[  "$REPLY" == "Stop Streisand" ]] && getout
