# Debian Interfaces Network (v1-net-config)

Static wired networking with ifupdown, the classic Debian stack driven by
`/etc/network/interfaces`. In this directory it is example number 1 (v1).

## What the Layer Does

- Installs the `ifupdown` package and enables `networking.service`.
- Writes `/etc/network/interfaces` with a static stanza for `net.iface`.
- Replaces `/etc/systemd/network/01-eth0.network`, which `rpi-device-base`
  installs with `DHCP=yes`, with a unit that marks the interface
  `Unmanaged=yes`. systemd-networkd stays running for other interfaces but
  leaves this one to ifupdown.

The layer runs after the device layer and after `systemd-net-min`
(`X-Env-Layer-AfterProvider: device,network-activator`), which is what makes
the replacement reliable.

DNS still works through systemd-resolved: Debian's ifupdown ships
`/etc/network/if-up.d/resolved`, which pushes `dns-nameservers` from the
stanza to resolved when the interface comes up.

## Generated File (defaults)

`/etc/network/interfaces`:

```text
source /etc/network/interfaces.d/*

auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 192.168.0.72/24
    gateway 192.168.0.1
    dns-nameservers 192.168.0.1
```

`/etc/systemd/network/01-eth0.network`:

```ini
[Match]
Name=eth0

[Link]
Unmanaged=yes
```

Setting `net.addr6` adds an `iface eth0 inet6 static` stanza with that address
and, if `net.gw6` is set, its gateway. The exact files for the defaults are
checked in under [deb-interfaces/etc/](deb-interfaces/etc/).

## Variables

See the table in [README.md](README.md#using-an-example). Example config:

```yaml
layer:
  base: trixie-minbase
  network: v1-net-config

net:
  addr: 10.0.0.5/24
  gw: 10.0.0.1
  dns: 10.0.0.1 1.1.1.1
```

## When to Use

- Headless and appliance-style hosts where a short, readable file is the goal.
- Hosts administered by people who already know ifupdown.
- Less suitable for desktops, which expect NetworkManager.

## Validate on the Device

```bash
ifquery --list
ifquery eth0
networkctl status eth0        # should report "unmanaged"
ip addr show eth0
ip route
resolvectl status eth0
```

## References

- `interfaces(5)`, `ifup(8)`
- `systemd.network(5)` for `Unmanaged=`
- RFC 1918 private IPv4 addressing
