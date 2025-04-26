#!/bin/bash

# Copyright (c) 2021 by Philip Collier, github.com/AB9IL
# This script is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version. There is NO warranty; not even for
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

setup_algo(){
    x-terminal-emulator -e bash -c  "cd /opt/algo/; uv venv /opt/algo/.env; \
    sed -i 's/include-system-site-packages = false/include-system-site-packages = true/' /opt/algo/.env/pyvenv.cfg; \
    source /opt/algo/.env/bin/activate && uv pip install -r /opt/algo/requirements.txt; \
    deactivate; read -p 'Press Enter to close.' line"
}

check_dependencies(){
    x-terminal-emulator -e bash -c  "cd /opt/algo/; \
    source /opt/algo/.env/bin/activate; \
    uv pip install -r /opt/algo/requirements.txt;
    read -p 'Press Enter to close.' line"
}

runalgo(){
    x-terminal-emulator -e bash -c  "cd /opt/algo/; \
    source /opt/algo/.env/bin/activate; \
    ./algo; read -p 'Press Enter to close.' line; deactivate"
}

getout(){
deactivate
exit
}

readfiles(){
   FILE="$(fd . "/opt/algo" -e md | \
        rofi -dmenu -p "Select File to read" \
        -mesg "Read one of these")"
        [[ -z "${FILE}" ]] || glow-wrapper "${FILE}"
}

OPTIONS="Set Up Algo First
Run Algo
Stop Algo
Check Dependencies
Open README files"

# Take the choice; exit if no answer matches options.
REPLY="$(echo -e "$OPTIONS" | rofi \
    -l 5 \
    -dmenu -p "Select Action" \
    -mesg "Set up and run a VPN on your own server.
Note: You should backup your SSH keys and server
credentials to a safe place off of this system.
See the README files in /opt/algo for more
information.")"

[[  "$REPLY" == "Set Up Algo First" ]] && setup_algo
[[  "$REPLY" == "Run Algo" ]] && runalgo
[[  "$REPLY" == "Stop Algo" ]] && getout
[[  "$REPLY" == "Check Dependencies" ]] && check_dependencies
[[  "$REPLY" == "Open README files" ]] && readfiles

