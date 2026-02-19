# Debian SystemD-Resolved Network

The /etc/resolv.conf file is now generated and linked to /run. This is the newest networking configuration.

Refer to this as version 3 (three). It integrates with both Systemd-resolved and NetworkManager (nmcli).

Output the named file with the correct indentations and line endings. It will be read as a special file name <priority>-<device>.network. Logs may reveal interface name not guarenteed in the journalctl log as this approach uses a matching rule to link to the device and modify the internal networking configuration of systemd. It then creates the resolv.conf and linked stub-resolv.conf.

It is important that you choose only 1 networking configuration approach and stick with it! Mixing configurations can cause thrashing and confusion to the resolver and network identification (as well as create maintenance headaches!).

See the layer definition for sample mmdebstrap instruction as shown below:

  customize-hooks:
    - |
      install -d "$1/etc/systemd/network"
      cat > "$1/etc/systemd/network/01-eth0.network" <<-EOF
      [Match]
      Name=eth0

      [Network]
      DHCP=no
      Address=192.168.0.72/24
      Gateway=192.168.0.1
      DNS=127.0.0.1
      DNS=1.1.1.1
      DNS=8.8.8.8
      IPv6AcceptRA=no
      LinkLocalAddressing=no
      EOF

Note: Address, Gateway and DNS values will be specific to your environment and network. The first DNS is pointed to 127.0.0.1 (localhost) to support a local DNS server prior to reaching out to internet-based DNS server(s).