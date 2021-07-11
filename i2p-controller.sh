#!/bin/bash

# Copyright (c) 2021 by Philip Collier, <webmaster@mofolinux.com>
# This script is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version. There is NO warranty; not even for
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Encoding=UTF-8

i2pstart(){
export https_proxy=127.0.0.1:4444
export HTTPS_PROXY=127.0.0.1:4444
export http_proxy=127.0.0.1:4444
export HTTP_PROXY=127.0.0.1:4444
export socks_proxy=127.0.0.1:14447
export SOCKS_PROXY=127.0.0.1:14447
export NO_PROXY='localhost, 127.0.0.1'
export no_proxy='localhost, 127.0.0.1'
/usr/bin/i2prouter start;
}

i2pstop(){
/usr/bin/i2prouter stop;
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

OPTIONS="Start I2P and configure proxy settings
Stop I2P and restore proxy settings"

# Take the choice; exit if no answer matches options.
REPLY="$(echo -e "$OPTIONS" | rofi \
    -dmenu -p "Manage I2P" \
    -lines 2)"

[[ -z "$REPLY" ]] && exit 1
[[  "$REPLY" == "Start I2P and configure proxy settings" ]] && i2pstart
[[  "$REPLY" == "Stop I2P and restore proxy settings" ]] && i2pstop
