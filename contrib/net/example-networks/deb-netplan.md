# Debian Netplan Network

This example demonstrates Netplan-based networking using /etc/netplan/00-installer.yaml.

In this repository, it is referred to as version 2 (v2).

## When to Use

1. Personal home: good for users who prefer YAML-based, declarative network configuration.
2. Small business: good for standardized host templates and mixed desktop/server estates.
3. Large enterprise: suitable for policy-driven provisioning pipelines with reproducible config files.

Netplan files are processed in lexical order. This example uses 00-* so local definitions are applied early and remain explicit.

Choose one networking stack per image whenever possible.

## Renderer Note

The optional renderer key determines which backend applies the network policy:

1. networkd for systemd-networkd
2. NetworkManager for nmcli/desktop-oriented management

## Configuration Example (mmdebstrap layer hook)

```yaml
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
```

## Validation and Operations

1. Validate generated model with: netplan generate
2. Inspect effective config with: netplan get
3. Validate backend state with: networkctl status (networkd) or nmcli device show (NetworkManager)
4. Confirm resolver state with: resolvectl status

## Standards and References

1. netplan specification and examples: https://netplan.readthedocs.io/
2. resolver file behavior: man 5 resolv.conf
3. private IPv4 addressing guidance: RFC 1918
4. IPv6 SLAAC behavior: RFC 4862

## Notes

Address, gateway, and DNS values must be adapted to your environment. Using 127.0.0.1 as the first DNS server is appropriate only when a local resolver service is configured on the host.