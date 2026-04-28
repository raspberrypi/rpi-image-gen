# Debian Interfaces Network

This example demonstrates ifupdown-style networking using /etc/network/interfaces.

In this repository, it is referred to as version 1 (v1).

## When to Use

1. Personal home: good when you want a minimal, static configuration with low complexity.
2. Small business: useful for fixed-role hosts (DNS, firewall, appliance-style nodes).
3. Large enterprise: generally better for specific static-use systems than broad desktop fleets.

Choose one networking stack per image. Avoid mixing stacks unless you have a clearly documented reason and test coverage.

## Configuration Example (mmdebstrap layer hook)

```yaml
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
```

## Validation and Operations

1. Confirm syntax and interface declarations with: ifquery --list and ifquery eth0
2. Confirm routing with: ip route
3. Confirm resolver path with: resolvectl status or cat /etc/resolv.conf

## Standards and References

1. ifupdown file format: man 5 interfaces
2. resolver file behavior: man 5 resolv.conf
3. private IPv4 addressing guidance: RFC 1918
4. IPv6 ULA guidance: RFC 4193

## Notes

Address, gateway, and DNS values must be adapted to your environment. Using 127.0.0.1 as the first DNS server is appropriate only if a local resolver is actually present on the host.