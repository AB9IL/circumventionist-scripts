#!/bin/bash

# Copyright (c) 2021 by Philip Collier, <webmaster@mofolinux.com>
# This script is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version. There is NO warranty; not even for
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

check_dependencies(){
x-terminal-emulator -e sh -c  "cd /opt/algo/ && python3 -m virtualenv --python=`which python3` envs && read line"
source "/opt/algo/.env/bin/activate" 
x-terminal-emulator -e sh -c "cd /opt/algo/ && python3 -m pip install -r requirements.txt && read line"
}

runalgo(){
python -m virtualenv --python=`which python3` env
source "/opt/algo/.env/bin/activate"
x-terminal-emulator -e sh -c  "cd /opt/algo/ && ./algo && read line"
}

getout(){
deactivate
exit
}

OPTIONS="Run Algo
Check Dependencies
Stop Algo"

# Take the choice; exit if no answer matches options.
REPLY="$(echo -e "$OPTIONS" | rofi \
    -lines 4 \
    -dmenu -p "OpenVPN - Select Action" \
    -mesg "Set up and run a VPN on your own server.
Note: You should backup your SSH keys and server
credentials to a safe place off of this system.
See the README files in /opt/algo for more
information.")"

[[  "$REPLY" == "Run Algo" ]] && runalgo
[[  "$REPLY" == "Check Dependencies" ]] && check_dependencies
[[  "$REPLY" == "Stop Algo" ]] && getout
