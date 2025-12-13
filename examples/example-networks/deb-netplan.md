# Debian Netplan Network

The /etc/netplan/<00-70>-filename.yaml is the next or first post-interfaces networking configuration file setup.

Refer to this as version 2 (two). It integrates with both Systemd-resolved and NetworkManager (nmcli).

Output the named file with the correct indentations and line endings. It will be read in alphabetical ascending order. There are references to existing netplan layers which are numbered 70 and above, so it is required to use lower numbers to invoke customizations.

The optional 'renderer' parameter determines whether systemd-resolved or NetworkManager domain name resolution is used.

It is important that you choose only 1 networking configuration approach and stick with it! Mixing configurations can cause thrashing and confusion to the resolver and network identification (as well as create maintenance headaches!).

See the layer defition for sample mmdebstrap instruction as shown below:

  setup-hooks:
    - |
      # Default network parameters (can be overridden by caller environment)
      NET_ADDR="192.168.0.72/24"
      NET_GW="192.168.0.1"
      NAMESERVER="127.0.0.1"
      IPV6_ADDR="2001:678:e68:f000::72/64"

      install -d "$1/etc/netplan"
      cat > "$1/etc/netplan/00-installer.yaml" <<-EOF
      network:
        version: 2
        ethernets:
          eth0:
            dhcp4: no
            dhcp6: no
            addresses:
              - ${NET_ADDR}
              - ${IPV6_ADDR}
            ipv6-privacy: true
            ipv6-address-generation: stable-privacy
            gateway4: ${NET_GW}
            nameservers:
              addresses: [${NAMESERVER}]
      EOF

Note: Addresses, Gateway and Nameserver values will be specific to your environment and network. The Nameserver is pointed to 127.0.0.1 (localhost) to support a local DNS server prior to reaching out to internet-based DNS server(s).