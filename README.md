# MOFO-Linux-v8
Scripts created for proxy or VPN access in [MOFO Linux version 8](https://mofolinux.com)

#### algo-controller.sh:
Requires [Algo VPN](https://github.com/trailofbits/algo) and associated Python3 dependencies.  Sets up the initial Algo management interface to start, stop, or check dependencies.

#### freenet-installer.sh:
Requires Freenet java installer package.  Presents a menu from which a user will install or decline to install the Freenet peer-to-peer platform for censorship-resistant communication.

#### i2p-controller.sh:
Requires Invisible Internet Project i2prouter package.  Start or stop i2prouter and configure proxy settings for other applications.

#### menu-vpngate:
Requires [DaveGallant/VPNGate](https://github.com/davegallant/vpngate) application.  Presents a menu of options for users of VPNGate: update the VPN server list, connect, disconnect, etc.

#### openvpn-controller.sh:
Requires OpenVPN and VPNGate (see menu-vpngate).  Easy user interface for starting or stopping OpenVPN connections or switching to the above menu-vpngate.

#### streisand-controller.sh:
Requires [StreisandEffect/streisand](https://github.com/StreisandEffect/streisand).  Sets up initial Streisand management interface to start, stop, or check dependencies.

#### tor-controller.sh:
Requires Tor, Proxychains4, Torsocks, Obfs4proxy.  Manage combined usage of Tor with extra obfuscation methods and circumvent measures preventing access to the Tor network.
