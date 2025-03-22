#!/bin/bash

# Copyright (c) 2021 by Philip Collier, <webmaster@mofolinux.com>
# This script is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version. There is NO warranty; not even for
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Encoding=UTF-8

install(){
	java -jar /opt/freenet/freenet_installer_offline.jar
}

OPTIONS="Install Freenet Application
Do Not Install Freenet Application"

# Take the choice; exit if no answer matches options.
REPLY="$(echo -e "$OPTIONS" | rofi \
    -dmenu -p "Freenet Installer - Select Action" \
    -lines 2)"

[[ -z "$REPLY" ]] && exit 1
[[  "$REPLY" == "Install Freenet Application" ]] && install
[[  "$REPLY" == "Do Not Install Freenet Application" ]] && exit 0
