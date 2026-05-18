# Debian systemd-networkd/systemd-resolved Network

This example demonstrates systemd-networkd policy files with resolver behavior from systemd-resolved.

In this repository, it is referred to as version 3 (v3).

## When to Use

1. Personal home: strong option for headless systems and low-overhead server nodes.
2. Small business: good for standardized server and appliance profiles.
3. Large enterprise: good when service-level control, deterministic unit files, and auditability are required.

The .network file naming model uses priority ordering (for example, 01-eth0.network). Lower numbers are applied first.

Choose one networking stack per image whenever possible.

## Resolver Model

With systemd-resolved enabled, /etc/resolv.conf is typically managed as a symlink to a runtime or generated resolver path. Validate which mode is active in your built image.

## Configuration Example (mmdebstrap layer hook)

```yaml
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
```

## Validation and Operations

1. Verify unit file syntax with: systemd-analyze verify /etc/systemd/network/*.network
2. Check link and route status with: networkctl status
3. Check resolver state with: resolvectl status
4. Confirm resolver symlink target with: ls -l /etc/resolv.conf

## Standards and References

1. network unit file format: man 5 systemd.network
2. resolver service behavior: man 8 systemd-resolved
3. resolver file semantics: man 5 resolv.conf
4. private IPv4 addressing guidance: RFC 1918
5. IPv6 SLAAC behavior: RFC 4862

## Notes

Address, gateway, and DNS values must be adapted to your environment. Using 127.0.0.1 as the first DNS server is appropriate only when a local resolver is configured on the same host.