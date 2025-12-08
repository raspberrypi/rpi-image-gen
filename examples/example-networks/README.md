# Example Networks

This folder defines example network configurations for the rpi-image-gen tooling.

It is provided to assist image builders with selecting and setting-up a given network scheme.

Mixing network configurations can cause maintenance and management issues. Try to stick with one approach consistently. Mixing them has difficult to diagnose issues. You may find you need to add additional or secondary network configuration settings for specific software. Consider it a work-around and inquire or advise the software maker/provider.

1. deb-interfaces is the original/oldest approach. The /etc/network/interfaces file can declare the network device configuration.
2. deb-netplan is the next developed approach. It utilizes YAML format for network definitions and description. It integrates to the NetworkManager (nmcli) graphical network management tool.
3. deb13-systemd-resolved is the newest approach covered here. It provides rules to the systemd-resolved daemon configuration. It generates (and overwrites!) the commonly known /etc/resolv.conf file.

I named deb13-systemd-resolved differently as that is the choice I have made for my given build. You are free to choose the others or venture to verify mix/matching them. I found the most success with Debian 13 using systemd-resolved configuration.

