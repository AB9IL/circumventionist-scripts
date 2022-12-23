# MOFO-Linux-v8
Scripts created for proxy or VPN access in [MOFO Linux version 8](https://mofolinux.com)

#### algo-controller.sh:
Requires [Algo VPN](https://github.com/trailofbits/algo) and associated Python3 dependencies.  Sets up the initial Algo management interface to start, stop, or check dependencies.

#### dl-vpngate:
Requires Python3 and Zenity.  Bulk downloads configs for OpenVPN connections from VPN Gate.  If VPN Gate is blocked in your country, use another circumvention tool to access the server. Once you can reach VPN Gate, this script gets you a truckload of ovpn files, and some of them should work!

#### freenet-installer.sh:
Requires Freenet java installer package.  Presents a menu from which a user will install or decline to install the Freenet peer-to-peer platform for censorship-resistant communication.

#### i2p-controller.sh:
Requires Invisible Internet Project i2prouter package.  Start or stop i2prouter and configure proxy settings for other applications.

#### menu-vpngate:
Requires [DaveGallant/VPNGate](https://github.com/davegallant/vpngate) application.  Presents a menu of options for users of VPN Gate: update the VPN server list, connect, disconnect, etc.

#### openvpn-controller.sh:
Requires OpenVPN and VPNGate (see menu-vpngate).  Easy user interface for starting or stopping OpenVPN connections or switching to the above menu-vpngate.

#### streisand-controller.sh:
Requires [StreisandEffect/streisand](https://github.com/StreisandEffect/streisand).  Sets up initial Streisand management interface to start, stop, or check dependencies.

#### tor-controller.sh:
Requires Tor, Proxychains4, Torsocks, Obfs4proxy.  Manage combined usage of Tor with extra obfuscation methods and circumvent measures preventing access to the Tor network.

#### tor-remote:
Requires ssh access to a server which has Tor running. Connect and disconnect to the remote server, which will provide unblocked and anonymous internet via Tor. You should configure your local system for key based ssh access to the server. Also, configure your web browser for proxy access through localhost and port 9050 (proxychains works). Tor-remote will forward traffic on port 9050 through the remote server. See the [tutorial for Tor-remote](https://bunkerbustervpn.com/tor-from-vps.html).

#### vivaldi-with-proxy:
Requires Vivaldi browser and Proxychains. This is a wrapper for the browser which switches to proxified browsing if other software creates a file "/tmp/proxyflag" or non-proxified without it. In Ubuntu or Debian Linux, use _update-alternatives_ to set x-www-browser path to this script (e.g. /usr/local/sbin/vivaldi-with-proxy). Tor-controller, tor-remote, or other proxying scrpts should set or remove the proxyflag as needed. If all works correctly, you may open Vivaldi and experience smooth, seamless operation in either configuration. 
