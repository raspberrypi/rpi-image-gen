# Debian Interfaces Network

The /etc/network/interfaces is the earliest networking configuration file setup.

I will refer to this as version 1 (one).

You output the named file with the correct indentations and line endings. It will be read.

It is important that you choose only 1 networking configuration approach and stick with it! Mixing configurations can cause thrashing and confusion to the resolver and network identification (as well as create maintenance headaches!).

See the layer defition for sample mmdebstrap instruction as shown below:

   setup-hooks:
    - |
      # Default network parameters (can be overridden by caller environment)
      NET_ADDR="192.168.0.72/24"
      NET_GW="192.168.0.1"
      NAMESERVER="127.0.0.1"
      IPV6_ADDR="2001:678:e68:f000::72/64"

      install -d "$1/etc/network"
      cat > "$1/etc/network/interfaces" <<-EOF
      auto eth0
      iface eth0 inet static
          address ${NET_ADDR}
          gateway ${NET_GW}
          dns-nameservers ${NAMESERVER}
      EOF

Note: Addresses, Gateway and Nameserver values will be specific to your environment and network. The Nameserver is pointed to 127.0.0.1 (localhost) to support a local DNS server prior to reaching out to internet-based DNS server(s).