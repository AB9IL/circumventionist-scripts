#!/bin/bash

# Copyright (c) 2025 by Philip Collier, github.com/AB9IL
# This script is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version. There is NO warranty; not even for
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# Run this script as root user (use sudo). This installer converts an existing
# Debian minimal or desktop system with Xfce into an opinionated respin with
# the same roster of features as in the MOFO Linux iso builds.
#
# MOFO Linux is a respin of Debian Sid. It will work on some, if not most,
# Debian variants. This version uses the Dynamic Window Manager (DWM), but it
# has been tested with i3,Sway, and Awesomewm.
#
# Refs:
# https://blog.aktsbot.in/swaywm-on-debian-11.html
# https://github.com/natpen/awesome-wayland
# https://github.com/swaywm/sway/wiki#gtk-applications-take-20-seconds-to-start
# https://lists.debian.org/debian-live/
#
# Switching to the Xanmod kernels:
# 1. Download the debs from SourceForge (image, headers, libc)
# 2. Install with dpkg -i *.deb
# 3. Purge the old linux-image and linux-image-amd64
# 4. Purge the old linux-headers and linux-headers-amd64
# 5. Pay attention to proper filenames for the initrd and vmlinuz files.

###############################################################################
# ROOT USER CHECK
###############################################################################
SCRIPT_VERSION="0.3"
echo -e "\nMOFO Linux Converter v$SCRIPT_VERSION"
# exit if not root
[[ $EUID -ne 0 ]] && echo -e "\nYou must be root to run this script." && exit

echo -e "You are about to make substantal changes to this system!\n"
echo -e "\n\nAre you sure you want to continue?"
echo ""
echo 'Please answer "yes" or "no"'
read line
case "$line" in
yes | Yes) echo "Okay, starting the conversion process!" ;;
*)
    echo '"yes" not received, exiting the script.'
    exit 0
    ;;
esac

###############################################################################
# SET VARIABLES
###############################################################################

USERNAME="$(logname)"

# most installations will go under the "working directory"
export working_dir="/usr/local/src"

export USERNAME
export ARCH="amd64"
export ARCH2="x86_64"
export BROWSER="vivaldi" # Browser can be any of: brave, firefox, vivaldi
export GOTGPT_VER="2.9.2"
export I2PD_VER="2.56.0"
export IPFS_VER="0.42.0"
export OBSIDIAN_VER="1.8.9"
export MeshChatVersion="v1.21.0"
export VPNGateVersion="0.3.1"
export LF_VER="34"
export LAZYGIT_VER="0.48.0"
export CYAN_VER="1.2.4"
export STARSH_VER="1.22.1"
export TIX_VER="3.33"
export FONT_VER="3.3.0"
export FONTS="Arimo.tar.xz FiraCode.tar.xz Inconsolata.tar.xz \
    NerdFontsSymbolsOnly.tar.xz"

###############################################################################
# START INSTALLING
###############################################################################

# Start this section with an apt configuration
# Then install nala for speed and aptitude for dependency resolution
echo 'APT::Install-Recommends "false";
APT::AutoRemove::RecommendsImportant "false";
APT::AutoRemove::SuggestsImportant "false";' >/etc/apt/apt.conf.d/99_norecommends

echo 'APT::Periodic::Update-Package-Lists "false";
APT::Periodic::Download-Upgradeable-Packages "false";
APT::Periodic::AutocleanInterval "false";
APT::Periodic::Unattended-Upgrade "false";' >/etc/apt/apt.conf.d/10periodic

echo '# Modernized from /etc/apt/sources.list
Types: deb deb-src
URIs: http://deb.debian.org/debian/
Suites: unstable
Components: main contrib non-free-firmware non-free
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

# Modernized from /etc/apt/sources.list
Types: deb deb-src
URIs: http://deb.debian.org/debian/
Suites: experimental
Components: main contrib non-free-firmware non-free
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
' >/etc/apt/sources.list.d/debian.sources

# Add Vivaldi repository
curl -fsSL https://repo.vivaldi.com/archive/linux_signing_key.pub |
    gpg --dearmor |
    sudo tee /usr/share/keyrings/vivaldi.gpg >/dev/null

echo 'Types: deb
URIs: https://repo.vivaldi.com/stable/deb/
Suites: stable
Components: main
Signed-By:' | sudo tee /etc/apt/sources.list.d/vivaldi.sources

apt update
apt --solver 3.0 --no-strict-pinning -y install nala aptitude git aria2

# uv is a great tool for Python. Use the installer script:
curl -fsSL https://astral.sh/uv/install.sh | sh

# Replace UFW with firewalld then set rules:
apt purge --autoremove -y ufw
apt --solver 3.0 --no-strict-pinning -y install firewalld
firewall-cmd --permanent --add-service={ssh,http,https}
systemctl reload firewalld

# Set up DNS over HTTPS:
apt --solver 3.0 --no-strict-pinning -y install dnss
sed -i "s/^.*supersede domain-name-servers.*;/supersede domain-name-servers 127.0.0.1" /etc/dhcp/dhclient.conf

echo '[main]
plugins=ifupdown,keyfile
dns=127.0.0.1
rc-manager=unmanaged

[ifupdown]
managed=false

[device]
wifi.scan-rand-mac-address=no' >/etc/NetworkManager/NetworkManager.conf

# Configure dnss to use alternative servers on 9981:
echo '# dnss can be run in 3 different modes, depending on the flags given to it:
# DNS to HTTPS (default), DNS to GRPC, and GRPC to DNS.
# This variable controls the mode, and its parameters.
# The default is DNS to HTTPS mode, which requires no additional
# configuration. For the other modes, see dnss documentation and help.
MODE_FLAGS="--enable_dns_to_https"

# Flag to configure monitoring.
# By default, we listen on 127.0.0.1:9981, but this variable allows you to
# change that. To disable monitoring entirely, leave this empty.
MONITORING_FLAG="--monitoring_listen_addr=127.0.0.1:9981 --https_upstream=https://91.239.100.100/dns-query"
' >/etc/default/dnss
systemctl enable dnss

# Force DNS nameserver to 127.0.0.1 (for dnss):
echo '#!/bin/bash

# This script exists because there seems to be no config which prevents
# from trying to use Google servers, which are blocked in certain regions.

# stop the dnss daemon
systemctl stop dnss

# overwrite Network Managers auto-generated resolv.conf files
ADDR="nameserver 127.0.0.1"
DNS_SERV="91.239.100.100"
FILES=(/run/resolvconf/resolv.conf /run/resolvconf/interface/systemd-resolved /etc/resolv.conf)
IFACEDIR="/run/resolvconf/interfaces"

[[ -d "$IFACEDIR" ]] && rm -rf "$IFACEDIR"/*

for FILE in "${FILES[@]}";do
    [[ -f "$FILE" ]] && echo "$ADDR" > $FILE
done

sleep 0.5

# start dnss socket
dnss --enable_dns_to_https -https_upstream https://"$DNS_SERV"/dns-query
' >/etc/network/if-up.d/zz-resolvconf
chmod +x /etc/network/if-up.d/zz-resolvconf

# Install wireguard-tools from the git mirror:
# https://github.com/WireGuard/wireguard-tools
# Clone the repo, cd into wireguard-tools/src, execute make && make install
(
    git clone https://github.com/WireGuard/wireguard-tools
    cd wireguard-tools/src || exit
    make
    make -j4 install
)

###############################################################################
# START OF GENERIC / PACKAGE INSTALLS (BASED ON DEBIAN WITH XFCE)
###############################################################################

# Map Caps Lock with ESC key (Get ESC when Caps Lock is pressed)
# Overwrite the file /etc/default/keyboard
echo '# KEYBOARD CONFIGURATION FILE

# Consult the keyboard(5) manual page.

XKBMODEL="pc105"
XKBLAYOUT="us"
XKBVARIANT=""
XKBOPTIONS="terminate:ctrl_alt_bksp,caps:escape"

BACKSPACE="guess"
' >/etc/default/keyboard

# set x11 resolution:
echo 'Section "Screen"
    Identifier "Screen0"
    Device "Card0"
    Monitor "Monitor0"
    DefaultDepth 24
    SubSection "Display"
        Depth 24
        Modes "1920x1080"
    EndSubSection
EndSection' >/etc/X11/xorg.conf.d/99-screen-resolution.conf

# set up the touchpad:
echo 'Section "InputClass"
    Identifier "touchpad"
    MatchIsTouchpad "on"
    Driver  "libinput"
    Option  "Tapping"	"on"
    Option  "TappingButtonMap"	"lrm"
    Option  "NaturalScrolling"	"on"
    Option  "ScrollMethod"	"twofinger"
EndSection' >/etc/X11/xorg.conf.d/90-touchpad.conf

# create the /etc/environment file
echo 'PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"
LC_ALL="en_US.UTF-8"
LANG="en_US.UTF-8"
VISUAL="vi"
export VISUAL
EDITOR="$VISUAL"
export EDITOR
NO_AT_BRIDGE=1
NLTK_DATA="/usr/share/nltk_data"
export STARSHIP_CONFIG="/etc/xdg/starship/starship.toml"
PIPEWIRE_LATENCY=256/48000
export PIPEWIRE_LATENCY' >/etc/environment

# enforce sourcing of environmental variables
echo '# make sure key environmental variables are
# picked up in minimalist environments
[ -f /etc/profile ] && . /etc/profile
[ -f /etc/environment ] && . /etc/environmen
' >/etc/X11/Xsession.d/91x11_source_profile

# Set X11 to have a higher key repeat rate
echo '#!/bin/sh

exec /usr/bin/X -nolisten tcp -ardelay 400 -arinterval 17 "$@"
' >/etc/X11/xinit/xserverrc

# Install editors and other items:
PKGS="fzf ripgrep fd-find glow qalc default-jre default-jre-headless ffmpeg \
lsp-plugins chrony pandoc pandoc-citeproc poppler-utils p7zip ruby-dev picom \
rng-tools-debian haveged irssi newsboat zathura zathura-ps zathura-djvu \
zathura-cb odt2txt atool w3m mediainfo parallel thunar thunar-volman ristretto \
libmpv2 mpv mplayer firmware-misc-nonfree firmware-iwlwifi firmware-brcm80211 \
firmware-intel-graphics firmware-intel-misc firmware-marvell-prestera \
firmware-mediatek firmware-nvidia-graphics meld gnome-screenshot gnome-keyring \
cmake libgtk-3-common audacity shellcheck shfmt luarocks black ruff tidy \
yamllint pypy3 dconf-editor net-tools blueman sqlite3 dbus-x11 obs-studio \
filezilla htop fastfetch tmux kodi rofi proxychains4 sshuttle tor torsocks \
obfs4proxy snowflake-client seahorse surfraw surfraw-extra usbreset libssl-dev \
libcurl4-openssl-dev software-properties-common apt-transport-https \
ca-certificates vivaldi-stable"
for PKG in $PKGS; do apt --solver 3.0 --no-strict-pinning -y install $PKG; done

# lsp-plugins should be hidden, but are not.
# append code in the launchers
sed -i '$aHidden=true' /usr/share/applications/in.lsp_plug*.desktop

# Note: use xfce4-appearance-settings to configure themes, icons, and fonts.

# get useful python tools:
PKGS="python3-numpy python3-scipy python3-sympy python3-bs4 python3-sql \
python3-pandas python3-html5lib python3-seaborn python3-matplotlib python3-pep8 \
python3-ruff python3-ijson python3-lxml python3-aiomysql python3-pynvim \
python3-neovim python3-ipython python3-pygame python3-scrapy python3-pyaudio \
python3-selenium python3-venv python3-virtualenv python3-virtualenvwrapper \
python3-nltk python3-numba python3-mypy python3-xmltodict python3-dask \
python3-sqlalchemy python3-openssl"
for PKG in $PKGS; do apt --solver 3.0 --no-strict-pinning -y install $PKG; done

# use pip for packages not in the regular repos
# execute as a loop so broken packages don't break the whole process
PKGS="pandas-datareader hq iq jq siphon sympad aria2p lastversion castero \
jupyterlab jupyter-book jupyter-lsp jupytext cookiecutter bash_kernel ilua \
types-seaborn pandas-stubs sounddevice nomadnet rns lxmf chunkmuncher"
for PKG in $PKGS; do
    python3 -m pip install --upgrade --break-system-packages $PKG
done

# use pip for a beta version:
#python3 -m pip install --upgrade --break-system-packages --pre <packagename>

# Install Nodejs and associated packages:
# read latest info: https://github.com/nodesource/distributions
NODE_MAJOR=22
curl -fsSL https://deb.nodesource.com/setup_$NODE_MAJOR.x -o nodesource_setup.sh
chmod +x nodesource_setup.sh
./nodesource_setup.sh
apt --solver 3.0 --no-strict-pinning -y install nodejs
# Test with: nodejs --version

# Use npm as the node package manager.
PKGS="prettier eslint_d jsonlint markdownlint readability-cli"
for PKG in $PKGS; do npm install -g $PKG; done

# Update node and prune cruft with:
npm update -g
npm prune

# Install yarn if desired
# npm install -g yarn

# install golang
# IMPORTANT:
# Updating golang will cause deletions of these:
#     gophernotes -- for Jupyterlab
#     gofmt  -- code formatter for Neovim
# See other notes for instructions to reinstall.
# The code below preserves current versions of gophernotes and gofmt
cp /usr/local/go/bin/{gofmt,gophernotes} /tmp/
wget -c "https://golang.org/dl/go1.21.1.linux-"$ARCH".tar.gz"
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.21.1.linux-"$ARCH".tar.gz
cp /tmp/{gofmt,gophernotes} /usr/local/go/bin/

# Add the following code to user's .profile:
# golang
# export GOROOT=/usr/local/go
# export GOPATH=$GOROOT
# export GOBIN=$GOPATH/bin
# export PATH=$PATH:$GOROOT

# Create symlink for gofmt
ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt

# Install Harper (English grammar checker)
(
    cd "$working_dir" || exit
    mkdir harper-ls
    cd harper-ls || exit
    wget -c https://github.com/Automattic/harper/releases/download/v"$HARP_VER"/harper-ls-"$ARCH2"-unknown-linux-gnu.tar.gz
    tar -xvzf --overwrite harper-ls-"$ARCH2"-unknown-linux-gnu.tar.gz
    chmod +x "$working_dir"/harper-ls/harper-ls
    ln -sf "$working_dir"/harper-ls/harper-ls /usr/local/bin/harper-ls
)

# Install the latest Neovim
(
    cd "$working_dir" || exit
    wget -c https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-"$ARCH2".tar.gz
    tar -xvzf --overwrite nvim-linux-"$ARCH2".tar.gz
    cd nvim-linux-"$ARCH2" || exit
    chown -R root:root ./*
    cp bin/* /usr/bin/
    cp -r share/{applications,icons,locale,man} /usr/share/
    rsync -avhc --delete --inplace --mkpath lib/nvim/ /usr/lib/nvim/
    rsync -avhc --delete --inplace --mkpath share/nvim/ /usr/share/nvim/

    # Install the Neovim configuration
    cd "$working_dir" || exit
    git clone https://github.com/AB9IL/nvim-configs
    cd nvim-configs || exit
    rsync -avhc --delete --inplace --mkpath nvim-minimal/ /root/.config/nvim/
    rsync -avhc --delete --inplace --mkpath nvim-minimal/ /etc/xdg/nvim/
    rsync -avhc --delete --inplace --mkpath nvim/ /home/"$USERNAME"/.config/nvim/
    chown -R "$USERNAME":"$USERNAME" /home/"$USERNAME"/.config/nvim/

    # get some npm and perl nvim assets
    npm install -g neovim
    curl -L https://cpanmin.us | perl - App::cpanminus
    cpanm Neovim::Ext
)

# Get dotfiles
printf "\nDownloading dot files"
(
    cd "$working_dir" || exit
    git clone https://github.com/AB9IL/Dotfiles
    cd Dotfiles || exit
    DIRS=".bashrc.d .w3m"
    for DIR in $DIRS; do
        cp -r "$DIR" /home/"$USERNAME"/
    done

    FILES=".bashrc .fzf.bash .inputrc .nanorc .tmux.conf \
        .vimrc .wgetrc .Xresources"
    for FILE in $FILES; do
        cp "$FILE" /home/"$USERNAME"/
    done

    FOLDERS="alacritty dconf castero dunst networkmanager-dmenu newsboat \
        picom rofi wezterm sxhkd systemd zathura"
    for FOLDER in $FOLDERS; do
        cp -r "$FOLDER" /home/"$USERNAME"/.config/"$FOLDER"
    done

    XDGFOLDERS="alacritty wezterm dunst"
    for XDGFOLDER in $XDGFOLDERS; do
        cp -r "$XDGFOLDER" /etc/xdg/"$XDGFOLDER"
    done
)

# set up the menu / app launcher
printf "\n Setting up the menu / app launcher"
(
    echo '#!/bin/bash

rofi -i \
	-modi combi \
	-show combi \
    -combi-modi "window,drun" \
    -display-drun "" \
	-monitor -1 \
	-columns 2 \
	-show-icons \
	-drun-match-fields "exec" \
' >/usr/bin/run-rofi
    chmod +x /usr/bin/run-rofi
)

# install nerd fonts
(
    printf "\nInstalling Nerd Fonts"
    cd "$working_dir" || exit
    for FONTPKG in $FONTS; do
        aria2c -x5 -s5 \
            https://github.com/ryanoasis/nerd-fonts/releases/download/v"$FONT_VER"/"$FONTPKG"
        tar -xvJf "$FONTPKG" -C /usr/share/fonts/truetype
        rm "$FONTPKG"
    done
    fc-cache -fv
)

# install the git updater
(
    cd "$working_dir" || exit
    git clone https://github.com/AB9IL/Updater-for-Gits-Etc
    chmod +x Updater-for-Gits-Etc/getgits.sh
    ln -sf "$working_dir"/Updater-for-Gits-Etc/getgits.sh \
        "$working_dir"/getgits.sh
)

###############################################################################
# END OF GENERIC / PACKAGE INSTALLS
###############################################################################

###############################################################################
# CONFIGURE JUPYTERLAB
###############################################################################
# NLTK needs extra data to work. Get it by using the Python REPL:
#  >>> import nltk
#  >>> nltk.download()
#  Navigate through the download settings:
#    d) Download --> c) Config -->
#    d) Set Data Dir ) and set the data download directory to
#      "/usr/share/nltk_data" then ( m) Main Menu --> q) Quit )
#  >>> nltk.download('popular')
#  >>> nltk.download('vader_lexicon')

# Textblob is also an NLP tool.

# For selenium, get the Firefox (gecko) webdriver from:
# https://github.com/mozilla/geckodriver
# The latest chromedriver can be downloaded from
# https://googlechromelabs.github.io/chrome-for-testing/
# Keep the actual executable at /usr/local/src/chromedriver-linux64/chromedriver
# and symlink to /usr/bin/chromedriver
# Check either driver by calling with the --version argument

# The path is FUBAR for each of {flake8,isort,yapf}:
# Fixed with wrappers (little bash scripts which execute the Python):
#  /usr/local/bin/flake8 containing "python -m flake8"
#  /usr/local/bin/isort containing "python -m isort"
#  /usr/local/bin/yapf containing "python -m yapf"

# The Bash kernel is in package bash_kernel
# Complete insallation with:
python3 -m bash_kernel.install

# The Lua kernel is in package ilua
# Just pip install; no further action needed

# Add go kernel to jupyterlab
# use gophernotes, placed binary in /usr/local/go/bin/
# kernel files in /usr/local/share/jupyter/kernels/gophernotes
# kernel.json has full path to the gophernotes binary
mkdir -p "$(go env GOPATH)"/src/github.com/gopherdata
(
    cd "$(go env GOPATH)"/src/github.com/gopherdata || exit
    git clone https://github.com/gopherdata/gophernotes
    cd gophernotes || exit
    git checkout -f v0.7.5
    go install
    mkdir -p ~/.local/share/jupyter/kernels/gophernotes
    cp kernel/* ~/.local/share/jupyter/kernels/gophernotes
    cd ~/.local/share/jupyter/kernels/gophernotes || exit
    chmod +w ./kernel.json # in case copied kernel.json has no write permission
    sed "s|gophernotes|$(go env GOPATH)/bin/gophernotes|" <kernel.json.in >kernel.json
)

# Add typescript and javascript kernels to Jupyterlab
npm install -g tslab
tslab install --python=python3

# As desired, verify that the kernels are installed
# jupyter kernelspec list

# Remove redundant ijavascript Kernel
npm uninstall -g --unsafe-perm ijavascript
npm uninstall ijavascript

# Add language server extension to Jupyterlab
# python3 -m pip install jupyter-lsp
# old method (deprecated): jupyter labextension install @krassowski/jupyterlab-lsp
# old method (deprecated): jupyter labextension uninstall @krassowski/jupyterlab-lsp

# If installed, remove unified-language-server, vscode-html-languageserver-bin

# After finishing all other work on Jupyterlab, rebuild it.
jupyter-lab build

################################################################################
# WINDOW MANAGERS
###############################################################################

# Remove xfce, bloat, and some Wayland apps I had installed...
# Don't replace lightdm with sddm (draws in too much KDE)
PKGS="lightdm* liblightdm* lightdm-gtk-greeter light-locker sddm* gdm xfce* \
libxfce* xfburn xfconf xfdesktop4 parole sway swaybg waybar greybird-gtk-theme \
yelp timeshift dosbox grsync remmina wofi kwayland geoclue* \
gnome-accessibility-themes gnome-desktop3-data gnome-icon-theme gnome-menus \
gnome-settings-daemon gnome-settings-daemon-common gnome-system* systemsettings"
for PKG in $PKGS; do sudo apt -y autoremove --purge $PKG; done

# For Wayland / Sway
# Sway Components to install:
# sway swaybg sway-notification-center waybar xwayland nwg-look

# For screenshots in Sway:
# Get the grimshot script
# https://github.com/swaywm/sway/blob/master/contrib/grimshot
# apt --solver 3.0 --no-strict-pinning -y install grim slurp

# Make the clipboard functional
# apt --solver 3.0 --no-strict-pinning -y install wl-clipboard clipman

# Here is some sway config code:
# configure clipboard functions:
# exec wl-paste -t text --watch clipman store
# exec wl-paste -p -t text --watch clipman store -P --histpath="~/.local/share/clipman-primary.json"
# acces the history with a keybind:
# bindsym $mod+h exec clipman pick -t wofi
# clear the clipboard with:
# bindsym Sshift+$mod+h exec clipman clear --all

###############################################################################
# For Awesomewm:
# apt --solver 3.0 --no-strict-pinning -y install awesome awesome-extra

###############################################################################
# For DWM:
# install dependencies DWM and the patches
# apt --solver 3.0 --no-strict-pinning -y install libxft-dev libx11-dev \
# libxinerama-dev libxcb-xkb-dev libx11-xcb-dev libxcb-res0-dev libxcb-xinerama0

# install DWM
# Download the latest release from suckless.org and extract it.
# Place the folder in /usr/local/src

# patch DWM
# example command: patch -p1 < dwm-my-new-patch.diff
# actual patches used:
#    alwayscenter
#    attachbottom
#    pertag
#    scratchpads
#    swallow
#    vanity gaps

### USE DWM-FLEXIPATCH ###
# After getting the patches to work well together, save a
# diff file for these:
#    config.def.h
#    config.mk
#    patches.def.h
#
#
# Here is a command to save the patch:
# (one file)    diff -u orig.config.def.h latest.config.def.h > config.patch
# (directories) diff -rubN original/ new/ > rockdove.patch

# Uncomment some lines in config.mk:
#     # uncomment near line 32:
#     XRENDER = -lXrender
#     # uncomment near line 49
#     XCBLIBS = -lX11-xcb -lxcb -lxcb-res

# Make the binary with:  rm config.h; make clean; make

# A complete DWM setup is available through git:
(
    cd "$working_dir" || exit
    git clone https://github.com/AB9IL/dwm-flexipatch
    git clone https://github.com/AB9IL/dwm-bar

    # Simlink the dwm binary to /usr/local/bin/dwm
    ln -sf "$working_dir"/dwm-flexipatch/dwm /usr/local/bin/dwm
)

# Install the .profile and .xinitrc files
(
    cd "$working_dir"/Dotfiles || exit
    FILES=".profile .xinitrc"
    for FILE in $FILES; do
        cp "$FILE" /home/"$USERNAME"/
    done
)

# Configure some systemd items as necessary
# Check the default target with:
systemctl get-default

# If it is "geaphical.target" then set it to "multiuser.target":
# systemctl set-default multi-user.target

# For X11 window managers, create a systemd unit file to reliably start X
echo '[Unit]
Description=Start X11 for the user
After=network.target

[Service]
Environment=DISPLAY=:0
ExecStart=/usr/bin/startx %h/.xinitrc
Restart=on-failure

[Install]
WantedBy=default.target
' >/etc/systemd/user/startx.service

# Create the enabling symlink for the normal user:
mkdir -p /home/"$USERNAME"/.config/systemd/user/default.target.wants
ln -sf /etc/systemd/user/startx.service \
    /home/"$USERNAME"/.config/systemd/user/default.target.wants/startx.service

# Alternatively, as the normal user (not root or sudo):
# reload the daemon, enable, and activate
# systemctl --user daemon-reload
# systemctl --user enable startx.service
# systemctl --user start startx.service

# make sure the user owns newly created items in the home folder
chown -R "$USERNAME":"$USERNAME" /home/"$USERNAME"

###############################################################################
# END WINDOW MANAGERS
###############################################################################

#set the cpu governor
echo 'GOVERNOR="performance"' >/etc/default/cpufrequtils

# configure rng-tools
sed -i "11s/.*/HRNGDEVICE=/dev/urandom/" /etc/default/rng-tools

# configure rng-tools-debian
sed -i "s|^.*\#HRNGDEVICE=/dev/null|HRNGDEVICE=/dev/urandom/|" /etc/default/rng-tools-debian

# Create a script for items to set up during boot time:
echo '#!/bin/bash

# usbfs memory
echo 0 > /sys/module/usbcore/parameters/usbfs_memory_mb

# set clocksource
# Note: timer freqs in /etc/sysctl.conf
echo "tsc" > /sys/devices/system/clocksource/clocksource0/current_clocksource

#configure for realtime audio
echo '@audio - rtprio 95
@audio - memlock 512000
@audio - nice -19' > /etc/security/limits.d/10_audio.conf
' >/usr/sbin/startup-items

# make the script executable:
chmod +x /usr/sbin/startup-items

# Set up a a systemd unit for startup-items:
echo '[Unit]
Description=Startup Items and Debloat Services
After=getty.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/startup-items

[Install]
WantedBy=default.target
' >/etc/systemd/system/startup-items.service

# Enable by creating a symlink to the unit (accomplish manually or with systemctl enable <unit name>)
ln -sf /etc/systemd/user/startup-items.service \
    /etc/systemd/system/default.target.wants/startup-items.service

# Create a script to accomplish tasks immediately prior to
# starting the graphical environment.
echo '#!/bin/bash

# copy skel to home because live build stopped doing it
cp -r /etc/skel/. /home/user/
chown -R user:user /home/user

# fix a potential driver issue causing xserver to fail
setcap CAP_SYS_RAWIO+eip /usr/lib/xorg/Xorg
' >/usr/sbin/session-items

# Create a systemd service for session-itsms:
echo '[Unit]
Description=Session-items before window manager
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/session-items

[Install]
WantedBy=default.target
' >/etc/systemd/system/session-items.service

# Enable by creating a symlink to the unit (accomplish manually or with systemctl enable <unit name>)
ln -sf /etc/systemd/user/session-items.service \
    /etc/systemd/system/default.target.wants/session-items.service

# Move some environmental variables out of ~/.profile and into the realm
# of systemd:
mkdir -p /etc/systemd/user/environment.d
echo '[User]
Environment="BROWSER=x-www-browser"
Environment="BROWSERCLI=w3m"
Environment="PISTOL_CHROMA_FORMATTER=terminal256"
Environment="JAVA_HOME=/usr/lib/jvm/default-java"
Environment="PIPEWIRE_LATENCY=256/48000"
' >/etc/systemd/user/environment.d/environment.conf

# Note that these are persistent, not reset on user login.

# The systemd units listed above are helpful, but the pivotal change was
# resetting the default target away from "graphical.target" and back to
# "multi-user.target" since we do not run a display manager.
#
# Check the default target with:
# systemctl get-default

# If it is "geaphical.target" then set it to "multiuser.target":
# systemctl set-default multi-user.target

###############################################################################
# INSTALL ACCESSORIES
###############################################################################
printf "\nInstalling some accessories"

# Do most of the work from /usr/local/src
cd "$working_dir" || exit

# install obsidian
printf "\nInstalling Obsidian"
(
    aria2c -x5 -s5 \
        https://github.com/obsidianmd/obsidian-releases/releases/download/v"$OBSIDIAN_VER"/obsidian_"$OBSIDIAN_VER"_"$ARCH".deb
    dpkg -i obsidian*.deb
    rm obsidian*.deb
)

# apt --solver 3.0 --no-strict-pinning -y install brightnessctl light

# install pipewire
# See the guide: https://trendoceans.com/install-pipewire-on-debian-11/
apt --solver 3.0 --no-strict-pinning -y install pipewire \
    pipewire-audio-client-libraries pipewire-jack

# Setting up Wezterm as the main terminal emulator:
# - create a new alternative for x-terminal-emulator
#   update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/wezterm 60
# - then:
#   update-alternatives --config editor
# - Select "wezterm" (not "open-wezterm-here"
# - use either syntax to launch apps in the terminal:
#   x-terminal-emulator -e <app-command>
#   x-terminal-emulator start -- <app-cammand>

# Install Rclone
printf "\nInstalling rclone"
(
    cd "$working_dir" || exit
    curl -O https://downloads.rclone.org/rclone-current-linux-amd64.zip
    unzip rclone-current-linux-amd64.zip -d rclone-current-linux-amd64
    rm rclone-current-linux-amd64.zip
    cd rclone-current-linux-amd64 || exit
    cp rclone /usr/bin/
    chmod 755 /usr/bin/rclone
    mkdir -p /usr/local/share/man/man1
    cp rclone.1 /usr/local/share/man/man1/
    mandb
)

# Install rclone Browser
# AppImage: https://github.com/kapitainsky/RcloneBrowser
# ( https://github.com/kapitainsky/RcloneBrowser/releases/download/1.8.0/rclone-browser-1.8.0-a0b66c6-linux-"$ARCH2".AppImage )

# Install Tixati (bit torrent client)
(
    cd "$working_dir" || exit
    aria2c -x5 -s5 \
        https://tixati.com/download/tixati_"$TIX_VER"-1_"$ARCH"
    dpkg -i tixati_"$TIX_VER"-1_"$ARCH".deb
    rm tixati*.deb
)

###############################################################################
# FLATPAK - PACSTALL - MAKEDEB
###############################################################################
printf "\nInstalling alternative software installers: Flatpak / Pacstall / Makedeb"

# Install Flatpak
apt --solver 3.0 --no-strict-pinning -y install flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install Pacstall
# bash -c "$(curl -fsSL https://pacstall.dev/q/install)"

# Optional: install makedeb and get software from makedeb.org
# Must install and make debs as normal user
# You may install the deb packages as root
# bash -ci "$(wget -qO - 'https://shlink.makedeb.org/install')"

# Install the Python support for Neovim:
# aapt --solver 3.0 --no-strict-pinning -y install python3-neovim python3-pynvim
# (use pip if the repos don't have them)
#
# Install Ruby support for Neovim:
# gem install neovim
#
# Set up Perl support for Neovim:
# curl -L https://cpanmin.us | perl - App::cpanminus
# cpanm Neovim::Ext;
#
# for Lua formatting, install Stylua binary from:
# https://github.com/JohnnyMorganz/Stylua/releases
#
# - get luacheck: apt --solver 3.0 --no-strict-pinning -y install luarocks; luarocks install luacheck
# - get shellcheck and shfmt: apt --solver 3.0 --no-strict-pinning -y install shellcheck shfmt
# - get black, python3-ruff, and ruff: apt --solver 3.0 --no-strict-pinning -y install black python3-ruff ruff
# - get markdownlint: apt --solver 3.0 --no-strict-pinning -y install ruby-mdl
# - get golangci_lint: https://github.com/golangci/golangci-lint/releases/

### Set Vivaldi to use DNS over HTTPS:
# visit vivaldi://settings/security
# Set up secure DNS in the browser(Cloudflare is okay)
### Add Extensions to Vivaldi
# Get the id for the extension,
# (bard for search engines) pkdmfoabhnkpkcacnmgilaeghiggdbgf
# then enter it in the text field at:
# https://crxviewer.com/
# download as zip, then unzip when download is complete
# visit chrome://extensions
# make sure developer mode is enabled
# to test temporarily, click button to "load unpacked"
# select the unzipped extension's folder.
# to keep permanently, move folder to ~/.config/vivaldi-extensions/
# load unpacked from there instead of downloads folder

# Plugins for GIMP
# Install GMIC and Elsamuko scripts and GIMP plugins!
# Note: may need a workaround because gimp-gmic cannot be installed
# Install LinuxBeaver's GEGL plugins for GIMP
# Download, extract, and copy to proper directory as per instructions.

# # Install Cyan (converts CMYK color profiles better than GIMP)
# (
#     cd "$working_dir" || exit
#     aria2c -x5 -s5 \
#         https://github.com/rodlie/cyan/releases/download/"$CYAN_VER"/Cyan-"$CYAN_VER"-Linux-"$ARCH2".tgz
#     tar -xvzf --overwrite Cyan*.tgz
#     mv Cyan*/* cyan/
#     rm -r Cyan*
#     chmod +x cyan/Cyan
#     ln -sf "$working_dir"/cyan/Cyan \
#         /usr/local/bin/Cyan
# )

# Install Lazygit
(
    cd "$working_dir" || exit
    mkdir lazygit
    aria2c -x5 -s5 \
        https://github.com/jesseduffield/lazygit/releases/download/v"$LAZYGIT_VER"/lazygit_"$LAZYGIT_VER"_Linux_"$ARCH2".tar.gz
    tar -xvzf --overwrite lazygit_* -C lazygit/
    rm lazygit_*.tar.gz
    chmod +x lazygit/lazygit
    ln -sf "$working_dir"/lazygit/lazygit \
        /usr/local/bin/lazygit
)

# Install Reticulum Meshchat
printf "\nInstalling Reticulum Meshchat"
# The meshchat appimage is large - over 150 MB !!
# Consider the CLI option for meshchat:
# https://github.com/liamcottle/reticulum-meshchat
mkdir /opt/reticulum
(
    cd /opt/reticulum || exit
    aria2c -x5 -s5 \
        https://github.com/liamcottle/reticulum-meshchat/releases/download/"$MeshChatVersion"/ReticulumMeshChat-"$MeshChatVersion"-linux.AppImage
    chmod +x ReticulumMeshChat*
)

# create a meshchat launcher:
echo '[Desktop Entry]
Type=Application
Name=Reticulum Meshchat
GenericName=Reticulum Mesh Chat
Comment=Mesh network communications powered by the Reticulum Network Stack.
Exec=/opt/reticulum/ReticulumMeshChat.AppImage
Icon=reticulum-meshchat.ico
Terminal=false
Categories=Network;
Keywords=network;chat;meshchat;meshnet;
' >/home/"$USERNAME"/.local/share/applications/reticulum-meshchat.desktop

# Install Python-tgpt
printf "\nInstalling Python-tgpt"

# Reference https://pypi.org/project/python-tgpt/
# Manually delete the old tgpt symlink and binary.
# Use uv pip install and set a virtual environment in /opt.
mkdir /opt/python-tgpt
uv venv /opt/python-tgpt

# edit /opt/python-tgpt/pyenv.cfg to allow use of system site packages:
sed -i "s/include-system-site-packages = false/include-system-site-packages = true/" /opt/python-tgpt/pyenv.cfg

# Install the radiostreamer and create a launcher
printf "\nInstalling the Internet Radio Streamer"
(
    cd "$working_dir" || exit
    git clone https://github.com/AB9IL/radiostreamer
    chmod +x "$working_dir"/radiostreamer/radiostreamer
    chmod 664 "$working_dir"/radiostreamer/radiostreams
    ln -sf "$working_dir"/radiostreamer/radiostreamer /usr/local/bin/radiostreamer
    ln -sf "$working_dir"/radiostreamer/radiostreams /home/"$USERNAME"/.config/radiostreams

    # create a radiostreamer launcher:
    echo '[Desktop Entry]
Version=1.0
Name=Internet Radio Playlist
GenericName=Internet Radio Playlist
Comment=Open an internet radio stream
Exec=radiostreamer gui
Icon=radio-icon
Terminal=false
Type=Application
Categories=AudioVideo;Player;Recorder;Network
' >/home/"$USERNAME"/.local/share/applications/radiostreamer.desktop
)

# Install networkmanager-dmenu
(
    cd "$working_dir" || exit
    git clone https://github.com/firecat53/networkmanager-dmenu
    chmod +x networkmanager-dmenu/networkmanager_dmenu
    ln -sf "$working_dir"/networkmanager-dmenu/networkmanager_dmenu \
        /usr/local/bin/networkmanager_dmenu

    # create a launcher:
    echo '[Desktop Entry]
Version=1.0
Name=Network Manager with Dmenu
GenericName=Manage network connections.
Comment=Manage network connections.
Exec=networkmanager_dmenu
Icon=preferences-system-network
Terminal=false
Type=Application
Categories=System;NetworkSettings;
' >/home/"$USERNAME"/.local/share/applications/networkmanager-dmenu.desktop
)

# Install Dyatlov Mapmaker (SDR Map)
printf "\nInstalling Dyatlov Mapmaker (SDR Map)"
(
    cd "$working_dir" || exit
    git clone https://github.com/AB9IL/dyatlov
    chown -R "$USERNAME":"$USERNAME"/dyatlov
    chmod +x dyatlov/kiwisdr_com-parse
    chmod +x dyatlov/kiwisdr_com-update

    # create a launcher:
    echo '[Desktop Entry]
Version=1.0
Name=SDR-Map
GenericName=Map of internet software defined radio
Comment=Map of internet software defined radios
Exec=supersdr-wrapper --map
Icon=globe-icon
Terminal=false
Type=Application
StartupNotify=true
Categories=AudioVideo;Player;Network;
' >/home/"$USERNAME"/.local/share/applications/sdr-map.desktop
)

# Install SuperSDR
printf "\nInstalling SuperSDR"
(
    cd "$working_dir" || exit
    git clone https://github.com/AB9IL/supersdr
    chown -R "$USERNAME":"$USERNAME"/supersdr
    chmod +x supersdr/supersdr.py
    # create a launcher:
    echo '[Desktop Entry]
Name=SuperSDR-Bookmarks
GenericName=Stream favorite radio stations via software defined radio.
Comment=Stream favorites on internet software defined radio.
Exec=supersdr-wrapper --bookmarks --gui
Icon=radio-icon
Terminal=false
Type=Application
StartupNotify=true
Categories=AudioVideo;Player;Network;
' >/home/"$USERNAME"/.local/share/applications/supersdr-bookmarks.desktop

    # create a launcher:
    echo '[Desktop Entry]
Name=SuperSDR-Kill
GenericName=SuperSDR Kill Frozen App
Comment=Kill SuperSDR if frozen.
Exec=supersdr-wrapper --kill
Icon=/usr/local/src/supersdr/icon.jpg
Terminal=false
Type=Application
Categories=HamRadio;
StartupNotify=true
' >/home/"$USERNAME"/.local/share/applications/supersdr-kill.desktop

    # create a launcher:
    echo '[Desktop Entry]
Name=SuperSDR-Servers
GenericName=SuperSDR Client for KiwiSDR and Web-888 servers.
Comment=Select favorite KiwiSDR and Web-888 servers.
Exec=supersdr-wrapper --servers --gui
Icon=/usr/local/src/supersdr/icon.jpg
Terminal=false
Type=Application
Categories=HamRadio;
StartupNotify=true
' >/home/"$USERNAME"/.local/share/applications/supersdr-servers.desktop
)

# Install SuperSDR-Wrapper
printf "\nInstalling SuperSDR-Wrapper"
(
    cd "$working_dir" || exit
    git clone https://github.com/AB9IL/supersdr-wrapper
    chown -R "$USERNAME":"$USERNAME" supersdr-wrapper/kiwidata
    chmod +x supersdr-wrapper/stripper
    chmod +x supersdr-wrapper/supersdr-wrapper
    ln -sf "$working_dir"/supersdr-wrapper/kiwidata \
        "$working_dir"/kiwidata
    ln -sf "$working_dir"/supersdr-wrapper/stripper \
        /usr/local/bin/stripper
    ln -sf "$working_dir"/supersdr-wrapper/supersdr-wrapper \
        /usr/local/bin/supersdr-wrapper
)

# Install Bluetabs
printf "\nInstalling Bluetabs"
(
    cd "$working_dir" || exit
    git clone https://github.com/AB9IL/bluetabs
    chmod +x bluetabs/bluetabs
    ln -sf "$working_dir"/bluetabs/bluetabs \
        /usr/local/bin/bluetabs
    ln -sf "$working_dir"/bluetabs/tw_alltopics \
        /home/"$USERNAME"/.config/tw_alltopics

    # create a launcher:
    echo '[Desktop Entry]
Version=1.0
Name=Bluetabs
GenericName=Watch multiple Microblog feeds at once.
Comment=Watch multiple Microblog feeds at once.
Exec=bluetabs gui
Icon=twitgrid
Terminal=false
Type=Application
Categories=Networking;Internet;
' >/home/"$USERNAME"/.local/share/applications/bluetabs.desktop
)

# Install glow-wrapper
printf "\nInstalling glow-wrapper"
(
    echo '#!/bin/bash

x-terminal-emulator -e glow -p "$1"
read line' >/usr/local/bin/glow-wrapper
    chmod +x /usr/local/bin/glow-wrapper
)

# Install Linux-clone script
printf "Installing Linux-clone script"
(
    cd "$working_dir" || exit
    git clone https://github.com/AB9IL/linux-clone
    chmod +x "$working_dir"/linux-clone/linux-clone
    ln -sf "$working_dir"/linux-clone/linux-clone \
        /usr/local/bin/linux-clone
)

# Install menu-surfraw
printf "Installing Menu-Surfraw"
(
    cd "$working_dir" || exit
    git clone https://github.com/AB9IL/surfraw-more-elvis
    rsync -av --exclude='LICENCE' --exclude='README.md' \
        "$working_dir"/surfraw-more-elvis/ \
        /usr/lib/surfraw/
    chmod +x /usr/lib/surfraw/
    git clone https://github.com/AB9IL/menu-surfraw
    chmod +x menu-surfraw/menu-surfraw
    ln -sf "$working_dir"/menu-surfraw/menu-surfraw \
        /usr/local/bin/menu-surfraw

    # create a launcher:
    echo '[Desktop Entry]
Version=1.0
Name=Surfraw Web Search
GenericName=Surfraw Web Search
Name[en_US]=Surfraw Web Search
Comment=Find web content using Rofi and Surfraw.
Exec=menu-surfraw
Icon=edit-find
Terminal=false
Type=Application
Categories=Internet;Web;' >/home/"$USERNAME"/.local/share/applications/search.desktop
)

# Install circumventionist scripts
# Must do this before the proxy and vpn scripts
printf "Installing Circumventionist-scripts"
(
    cd "$working_dir" || exit
    git clone https://github.com/AB9IL/circumventionist-scripts
)

# Install the browser proxifier script
printf "\nInstalling browser proxifier scripts"
(
    cd "$working_dir" || exit
    chmod +x circumventionist-scripts/"$BROWSER"-with-proxy
    ln -sf "$working_dir"/circumventionist-scripts/brave-with-proxy \
        /usr/local/bin/brave-with-proxy
)

# Install lf file manager
printf "\nInstalling lf command line file manager"
(
    cd "$working_dir" || exit
    mkdir lf_linux_amd64
    cd lf_linux_"$ARCH" || exit
    aria2c -x5 -s5 \
        https://github.com/gokcehan/lf/releases/download/r"$LF_VER"/lf-linux-"$ARCH".tar.gz
    tar -xvzf --overwrite lf*.gz
    chmod +x lf
    rm lf*.gz
    cd "$working_dir" || exit
    ln -sf "$working_dir"/lf_linux_"$ARCH"/lf \
        /usr/local/bin/lf
    mkdir /etc/lf
    cp Dotfiles/lfrc /etc/lf/lfrc

    # create a launcher:
    echo '[Desktop Entry]
Type=Application
Name=lf
Name[en]=lf
GenericName=Terminal file manager.
Comment=Terminal file manager.
Icon=utilities-terminal
Exec=lf
Terminal=true
Categories=files;browser;manager;
' >/home/"$USERNAME"/.local/share/applications/lf.desktop
)

# Install pistol file previewer
(
    cd "$working_dir" || exit
    aria2c -x5 -s5 \
        https://github.com/doronbehar/pistol/releases/download/v0.5.2/pistol-static-linux-x86_64
    mkdir pistol
    mv pistol-* pistol/pistol
    chmod +x pistol/pistol
    ln -sf "$working_dir"/pistol/pistol \
        /usr/local/bin/pistol
)

# Install VPNGate client and scripts
printf "\nInstalling VPNGate client and scripts"
(
    cd "$working_dir" || exit
    mkdir vpngate
    cd vpngate || exit
    aria2c -x5 -s5 \
        https://github.com/davegallant/vpngate/releases/download/v"$VPNGateVersion"/vpngate_"$VPNGateVersion"_linux_"$ARCH".tar.gz
    tar -xvzf --overwrite vpn*.gz
    cd "$working_dir" || exit
    chmod +x vpngate/vpngate
    rm vpngate/vpn*.gz
    ln -sf "$working_dir"/vpngate/vpngate \
        /usr/local/bin/vpngate

    # make executable and symlink
    chmod +x circumventionist-scripts/dl_vpngate
    ln -sf "$working_dir"/circumventionist-scripts/dl_vpngate \
        /usr/local/bin/dl_vpngate

    # make executable and symlink
    chmod +x circumventionist-scripts/menu-vpngate
    ln -sf "$working_dir"/circumventionist-scripts/menu-vpngate \
        /usr/local/bin/menu-vpngate

    # create a launcher:
    echo '[Desktop Entry]
Name[en_US]=VPNGate Download
Name=VPNGate Download
GenericName=Download VPNGate OpenVPN configs.
Comment[en_US]=Download VPNGate OpenVPN configs.
Icon=vpngate
Exec=dl_vpngate 50
Type=Application
Terminal=false
' >/home/"$USERNAME"/.local/share/applications/dl_vpngate.desktop

    # create a launcher:
    echo '[Desktop Entry]
Name[en_US]=VPNGate Connect
Name=VPNGate Connect
GenericName=Manage VPNGate (OpenVPN) connections.
Comment[en_US]=Manage VPNGate (OpenVPN) connections.
Icon=vpngate
Exec=menu-vpngate
Type=Application
Terminal=false
' >/home/"$USERNAME"/.local/share/applications/vpngate.desktop
)

# Install proxy fetchers
printf "\nInstalling proxy fetchers"
(
    cd "$working_dir" || exit
    git clone https://github.com/stamparm/fetch-some-proxies
    chmod +x fetch-some-proxies/fetch.py
    git clone https://github.com/AB9IL/fzproxy
    chmod +x fzproxy/fzproxy
    ln -sf "$working_dir"/fzproxy/fzproxy \
        /usr/local/bin/fzproxy
    cp "$working_dir"/fzproxy/proxychains4.conf \
        /etc/
)

# Install Menu-Wireguard
printf "\nInstalling Menu-Wireguard"
(
    cd "$working_dir" || exit
    git clone https://github.com/AB9IL/menu-wireguard
    chmod +x menu-wireguard/menu-wireguard
    ln -sf "$working_dir"/menu-wireguard/menu-wireguard \
        /usr/local/bin/menu-wireguard

    # create a launcher:
    echo '[Desktop Entry]
Name[en_US]=Wireguard
GenericName=Manage Wireguard VPN connections.
Name=wireguard
Comment[en_US]=Manage Wireguard VPN connections.
Icon=wireguard
Exec=sudo menu-wireguard gui
Type=Application
Terminal=false
' >/home/"$USERNAME"/.local/share/applications/wireguard.desktop
)

# Install OpenVPN-controller
printf "\nInstalling OpenVPN Connection Manager"
(
    cd "$working_dir" || exit
    chmod +x "$working_dir"/circumventionist-scripts/openvpn-controller.sh
    ln -sf "$working_dir"/circumventionist-scripts/openvpn-controller.sh \
        /usr/local/bin/openvpn-controller.sh
)

# Install Sshuttle controller
printf "\Installing Sshuttle controller"
(
    cd "$working_dir" || exit
    chmod +x "$working_dir"/circumventionist-scripts/sshuttle-controller
    ln -sf "$working_dir"/circumventionist-scripts/sshuttle-controller \
        /usr/local/bin/sshuttle-controller
)

# Install Tor-Remote
printf "\nInstalling Tor-Remote"
(
    cd "$working_dir" || exit
    chmod +x "$working_dir"/circumventionist-scripts/tor-remote
    ln -sf "$working_dir"/circumventionist-scripts/tor-remote \
        /usr/local/bin/tor-remote
)

# Install Tor-controller
(
    cd "$working_dir" || exit
    chmod +x "$working_dir"/circumventionist-scripts/tor-controller.sh
    ln -sf "$working_dir"/circumventionist-scripts/tor-controller.sh \
        /usr/local/bin/tor-controller.sh
)

# Install Algo-Controller
printf "\nInstalling Algo-Controller"
(
    cd "$working_dir" || exit
    chmod +x "$working_dir"/circumventionist-scripts/algo-controller.sh
    ln -sf "$working_dir"/circumventionist-scripts/algo-controller.sh \
        /usr/local/bin/algo-controller.sh
)

# Install Starship prompt
printf "\nInstalling Starship prompt"
(
    cd "$working_dir" || exit
    mkdir starship
    aria2c -x5 -s5 \
        https://github.com/starship/starship/releases/download/v"$STARSH_VER"/starship-"$ARCH2"-unknown-linux-gnu.tar.gz
    tar -xvzf --overwrite starship-*.gz -C starship/
    chmod +x starship/starship
    ln -sf "$working_dir"/starship/starship \
        /usr/local/bin/starship
    cp Dotfiles/starship.toml /home/"$USERNAME"/.config/
    rm starship-*.gz
)

# Install system scripts
printf "Installing system scripts"
(
    cd "$working_dir" || exit
    git clone https://github.com/AB9IL/Catbird-Linux-Scripts

    # system exit or shutdown
    chmod +x Catbird-Linux-Scripts/system-exit
    ln -sf "$working_dir"/Catbird-Linux-Scripts/system-exit \
        /usr/local/bin/system-exit

    # usb reset utility
    chmod +x Catbird-Linux-Scripts/usbreset-helper
    ln -sf "$working_dir"/Catbird-Linux-Scripts/usbreset-helper \
        /usr/local/bin/usbreset-helper
    cp Catbird-Linux-Scripts/system.rasi \
        /usr/share/rofi/themes/system.rasi

    # create a launcher
    echo '[Desktop Entry]
Version=1.0
Name=System Shutdown
GenericName=Log out or shut down the computer.
Comment=Log out or shut down the computer.
Exec=system-exit
Icon=system-shutdown
Terminal=false
Type=Application
Categories=System;Shutdown;
' >/home/"$USERNAME"/.local/share/applications/shutdown.desktop

    # locale manager
    chmod +x Catbird-Linux-Scripts/locale-manager
    ln -sf "$working_dir"/Catbird-Linux-Scripts/locale-manager \
        /usr/local/bin/locale-manager

    # create a launcher
    echo '[Desktop Entry]
Type=Application
Name=Locale Manager
Name[en]=Locale Manager
GenericName=Change system languages and locales.
Comment=Change system languages and locales.
Icon=utilities-terminal
Exec=locale-manager
Terminal=false
Categories=Language;System
' >/home/"$USERNAME"/.local/share/applications/locale-manager.desktop

    # Install glow-wrapper
    chmod +x Catbird-Linux-Scripts/glow-wrapper
    ln -sf "$working_dir"/Catbird-Linux-Scripts/glow-wrapper \
        /usr/local/bin/glow-wrapper

    # Install make-podcast script
    chmod +x Catbird-Linux-Scripts/make-podcast
    ln -sf "$working_dir"/Catbird-Linux-Scripts/make-podcast \
        /usr/local/bin/make-podcast

    # Install make-screencast script
    chmod +x Catbird-Linux-Scripts/make-screencast
    ln -sf "$working_dir"/Catbird-Linux-Scripts/make-screencast \
        /usr/local/bin/make-screencast

    # Install note-sorter script
    chmod +x Catbird-Linux-Scripts/note-sorter
    ln -sf "$working_dir"/Catbird-Linux-Scripts/note-sorter \
        /usr/local/bin/note-sorter
    ln -sf "$working_dir"/Catbird-Linux-Scripts/note-sorter \
        /usr/local/bin/vimwiki

    # create a launcher
    echo '[Desktop Entry]
Type=Application
Name=Note Sorter
Name[en]=Note Sorter
GenericName=Search and sort your notes.
Comment=Search and sort markdown notes.
Icon=utilities-terminal
Exec=note-sorter
Terminal=true
Categories=Text;Editor;Programming
MimeType=text/english;text/plain;text/x-makefile;text/x-c++hdr;text/x-c++src;text/x-chdr;text/x-csrc;text/x-java;text/x-moc;text/x-pascal;text/x-tcl;text/x-tex;application/x-shellscript;text/x-c;text/x-c++;
' >/home/"$USERNAME"/.local/share/applications/note-sorter.desktop

    # Set up Roficalc
    chmod +x Catbird-Linux-Scripts/roficalc
    ln -sf "$working_dir"/Catbird-Linux-Scripts/roficalc \
        /usr/local/bin/roficalc

    # create a launcher for roficalc
    echo '[Desktop Entry]
Type=Application
Name=Roficalc
Name[en]=Roficalc
GenericName=Rofi Calculator
Comment=Do mathematical calculations in Rofi.
Icon=utilities-terminal
Exec=roficalc
Terminal=false
Categories=Text;Calculator;Programming
' >/home/"$USERNAME"/.local/share/applications/roficalc.desktop

    # set the desktop wallpaper
    ln -sf "$working_dir"/Catbird-Linux-Scripts/wallpaper.png \
        /usr/share/backgrounds/wallpaper.png
)

# create a launcher for castero
echo '[Desktop Entry]
Type=Application
Name=Castero
Name[en]=Castero
GenericName=Podcast player
Comment=Terminal podcast player
Icon=utilities-terminal
Exec=castero
Terminal=true
Categories=Network;Internet;
' >/home/"$USERNAME"/.local/share/applications/castero.desktop

# create a launcher for irssi
echo '[Desktop Entry]
Type=Application
Name=irssi
Name[en]=irssi
GenericName=Terminal IRC client.
Comment=Terminal IRC client.
Icon=utilities-terminal
Exec=irssi
Terminal=true
Categories=Network;Internet;
' >/home/"$USERNAME"/.local/share/applications/irssi.desktop

# create a launcher for newsboat
echo '[Desktop Entry]
Type=Application
Name=Newsboat
Name[en]=Newsboat
GenericName=Terminal RSS reader
Comment=Terminal RSS / Atom reader.
Icon=utilities-terminal
Exec=newsboat
Terminal=true
Categories=Network;Internet;
' >/home/"$USERNAME"/.local/share/applications/newsboat.desktop

# install python-tgpt
source /opt/python-tgpt/bin/activate
uv pip install python-tgpt

# Start a session with:
# pytgpt interactive "<Kickoff prompt (though not mandatory)>"

# Terminate the session with:
# exit

# Deactivate the virtual environment with:
# deactivate

# Set up the wrapper script to accomplish activation,
# running, and deactivation of python-tgpt.
chmod +x "$working_dir"/Catbird-Linux-Scripts/pytgpt-wrapper
ln -sf "$working_dir"/Catbird-Linux-Scripts/pytgpt-wrapper \
    /usr/local/bin/pytgpt-wrapper
chmod +x /usr/local/bin/pytgpt-wrapper

# create a launcher for python-tgpt
echo '[Desktop Entry]
Type=Application
Name=Terminal GPT
Name[en]=pyTerminal GPT
GenericName=pyTerminal GPT Chatbots.
Comment=Access AI chatbots from the terminal.
Icon=utilities-terminal
Exec=pytgpt-wrapper
Terminal=true
Categories=ai;gpt;browser;chatbot;
' >/home/"$USERNAME"/.local/share/applications/pytgpt.desktop

# create the providers list
echo 'auto
phind
perplexity
blackboxai
koboldai
ai4chat' >/opt/python-tgpt/providers

# install golang-based tgpt
printf "\nInstalling Golang-based tgpt"
(
    cd "$working_dir" || exit
    mkdir gotgpt
    cd gotgpt || exit
    aria2c -x5 -s5 \
        https://github.com/aandrew-me/tgpt/releases/download/v"$GOTGPT_VER"/tgpt-linux-"$ARCH"
    chmod +x tgpt-linux*
    git clone https://github.com/AB9IL/gotgpt-wrapper
    chmod +x /usr/local/bin/gotgpt-wrapper
    ln -sf "$working_dir"/gotgpt-wrapper/gotgpt-wrapper \
        /usr/local/bin/gotgpt-wrapper

    # create a launcher for Golang-based-tgpt
    echo '[Desktop Entry]
Type=Application
Name=goTerminal GPT
Name[en]=goTerminal GPT
GenericName=goTerminal GPT Chatbots.
Comment=Access AI chatbots from the terminal.
Icon=utilities-terminal
Exec=gotgpt-wrapper
Terminal=true
Categories=ai;gpt;browser;chatbot;
' >/home/"$USERNAME"/.local/share/applications/gotgpt.desktop
)

# Set alternatives as below:
# Web browser:
update-alternatives --install /usr/bin/www-browser www-browser /usr/local/bin/"$BROWSER"-with-proxy 60 &&
    update-alternatives --config www-browser
update-alternatives --install /usr/bin/x-www-browser x-www-browser /usr/local/bin/"$BROWSER"-with-proxy 60 &&
    update-alternatives --config x-www-browser
update-alternatives --install /usr/bin/debian-sensible-browser debian-sensible-browser /usr/local/bin/"$BROWSER"-with-proxy 60 &&
    update-alternatives --config debian-sensible-browser
update-alternatives --install /usr/bin/gnome-www-browser gnome-www-browser /usr/local/bin/"$BROWSER"-with-proxy 60 &&
    update-alternatives --config gnome-www-browser

# Vi and Vim:
update-alternatives --install /usr/bin/vi vi /usr/bin/nvim 60 &&
    update-alternatives --config vi
update-alternatives --install /usr/bin/vim vim /usr/bin/nvim 60 &&
    update-alternatives --config vim
update-alternatives --install /usr/bin/editor editor /usr/bin/nvim 60 &&
    update-alternatives --config editor

# Terminal emulators:
update-alternatives --install /usr/bin/xterm xterm /usr/bin/wezterm 60 &&
    update-alternatives --config xterm
update-alternatives --install /usr/bin/xterm-256color xterm-256color /usr/bin/wezterm 60 &&
    update-alternatives --config xterm-256color
update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/wezterm 60 &&
    update-alternatives --config x-terminal-emulator
update-alternatives --install /usr/bin/debian-x-terminal-emulator debian-x-terminal-emulator /usr/bin/weezterm 60 &&
    update-alternatives --config debian-x-terminal-emulator

# Install Algo VPN Server Manager
printf "\n Algo VPN Server Manager"
(
    cd /opt || exit
    git clone the algo repo
    git clone https://github.com/trailofbits/algo
    cd algo || exit

    # python3 -m pip uninstall virtualenv
    # apt install --reinstall python3-virtualenv
    # as user "mofo" run this command in the algo directory

    uv venv /opt/algo/.env &&
        # edit /opt/python-tgpt/pyenv.cfg to allow use of system site packages:
        sed -i "s/include-system-site-packages = false/include-system-site-packages = true/" /opt/algo/.env/pyenv.cfg
    # activate the virtual environment and then install the tools
    source /opt/algo/.env/bin/activate &&
        uv pip install -r requirements.txt
    deactivate
)

# Install Outline
printf "\nOutline"
(
    cd "$working_dir" || exit
    aria2c -x5 -s5 \
        https://s3.amazonaws.com/outline-releases/client/linux/stable/outline-client_"$ARCH".deb
    dpkg -i outline-client_"$ARCH".deb
    rm outline-*.deb
)

# Install IPFS-Desktop and IPFS-Companion (Vivaldi plugin)
(
    cd "$working_dir" || exit
    # switch to IPFS deb installation:
    aria2c -x5 -s5 \
        https://github.com/ipfs/ipfs-desktop/releases/download/v"$IPFS_VER"/ipfs-desktop-"$IPFS_VER"-linux-"$ARCH".deb
    dpkg -i ipfs-desktop-"$IPFS_VER"-linux-"$ARCH".deb
    rm ipfs-desktop-*.deb
    # Get the IPFS companion app and manually install the browser extension
    #(ipfs-companion) https://github.com/ipfs/ipfs-companion/releases/
)

# # Install element messenger (deb package):
# (
#     wget -O /usr/share/keyrings/element-io-archive-keyring.gpg \
#         https://packages.element.io/debian/element-io-archive-keyring.gpg
#     echo "Types: deb
# URIs: https://packages.element.io/debian/
# Suites: default
# Components: main
# Signed-By: /usr/share/keyrings/element-io-archive-keyring.gpg" > /etc/apt/sources.list.d/element-io.list
#     apt update; apt install element-desktop
# )

# Install Element messenger (web app):
(
    cd "$working_dir" || exit
    chmod +x circumventionist-scripts/element-web.sh
    ln -sf "$working_dir"/circumventionist-scripts/element-web.sh \
        /usr/local/bin/element-web.sh
    cp circumventionist-scripts/launchers/element-web.desktop /home/user/.local/share/applications/element-web.desktop
)

# Install Discord Chat (web app):
(
    cd "$working_dir" || exit
    chmod +x circumventionist-scripts/discord-web.sh
    ln -sf "$working_dir"/circumventionist-scripts/discord-web.sh \
        /usr/local/bin/discord-web.sh
    cp circumventionist-scripts/launchers/discord-web.desktop /home/user/.local/share/applications/discord-web.desktop
)

# Install signal-messenger (BROKEN!  Unsigned key.)
(
    wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor >signal-desktop-keyring.gpg
    cat signal-desktop-keyring.gpg | tee /usr/share/keyrings/signal-desktop-keyring.gpg >/dev/null
    echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' | tee /etc/apt/sources.list.d/signal-xenial.list
    apt update
    apt install signal-desktop
    #### Fuck this Signal nonsense.  They are not keeping it up.
)

# Install Telegram messenger (web app):
(
    cd "$working_dir" || exit
    chmod +x circumventionist-scripts/telegram-web.sh
    ln -sf "$working_dir"/circumventionist-scripts/telegram-web.sh \
        /usr/local/bin/telegram-web.sh
    cp circumventionist-scripts/launchers/telegram-web.desktop /home/user/.local/share/applications/telegram-web.desktop
)

# # Install Telegram-Desktop
# (
#     cd "$working_dir" || exit
#     aria2c -x5 -s5 https://telegram.org/dl/desktop/linux
#     tar -xvf tsetup.*.tar.xz -C /opt/Telegram
#     chmod +x /opt/Telegram/Telegram
#     chmod +x /opt/Telegram/Updater
#     echo '[Desktop Entry]
# Name=Telegram Desktop
# Comment=Official desktop version of Telegram messaging app
# TryExec=/opt/Telegram/Telegram
# Exec=/opt/Telegram/Telegram -- %u
# Icon=telegram
# Terminal=false
# StartupWMClass=TelegramDesktop
# Type=Application
# Categories=Chat;Network;InstantMessaging;Qt;
# MimeType=x-scheme-handler/tg;
# Keywords=tg;chat;im;messaging;messenger;sms;tdesktop;
# Actions=quit;
# DBusActivatable=true
# SingleMainWindow=true
# X-GNOME-UsesNotifications=true
# X-GNOME-SingleWindow=true
#
# [Desktop Action quit]
# Exec=/opt/Telegram/Telegram -quit
# Name=Quit Telegram
# Icon=application-exit' >/home/"$USERNAME"/.local/share/applications/org.telegram.desktop
# )

# Install I2P
(
    cd "$working_dir" || exit
    aria2c -x5 -s5 \
        https://github.com/PurpleI2P/i2pd/releases/download/"$I2PD_VER"/i2pd_"$I2PD_VER"-1_"$ARCH".deb
    dpkg -i i2pd_"$I2PD_VER"-1_"$ARCH".deb
    rm i2pd*.deb
)

# Install v2ray
(
    # Install support for v2ray with v2mess capability
    # visit https://github.com/v2fly/v2ray-core
    # install:
    # bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)
    # Install the latest release of GeoIP.dat and GeoSite.dat:
    # bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-dat-release.sh)
    # uninstall:
    # bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh) --remove

    # >>> Installation script with systemd support <<<
    https://github.com/v2fly/fhs-install-v2ray

    # get graphical V2ray gui qv2ray
    https://github.com/Qv2ray/qv2ray

    # symlink the v2ray-controller script
    chmod +x "$working_dir"/circumventionist-scripts/v2ray-controller.sh
    ln -sf "$working_dir"/circumventionist-scripts/v2ray-controller.sh \
        /usr/local/bin/v2ray-controller.sh
)

# set ownership of all items in the home folder
chown -R "$USERNAME":"$USERNAME" /home/"$USERNAME"

echo "MOFO Linux Setup is complete!"
