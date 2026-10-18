# Debian systemd-networkd / systemd-resolved Network (v3-net-config)

Static wired networking as a plain systemd-networkd unit, with DNS handled by
systemd-resolved. In this directory it is example number 3 (v3).

## What the Layer Does

- Installs no packages. `trixie-minbase` already enables systemd-networkd and
  systemd-resolved through the `systemd-net-min` and `systemd-resolved`
  layers.
- Overwrites `/etc/systemd/network/01-eth0.network`. `rpi-device-base`
  installs that file with `DHCP=yes`; writing the same filename replaces it
  with the static configuration. Keeping the `01-` prefix matters, because
  networkd applies the first matching unit in filename order.

The layer runs after the device layer and after `systemd-net-min`
(`X-Env-Layer-AfterProvider: device,network-activator`), so the overwrite is
guaranteed to happen last.

## Generated File (defaults)

`/etc/systemd/network/01-eth0.network`:

```ini
[Match]
Name=eth0

[Link]
RequiredForOnline=yes

[Network]
DHCP=no
IPv6AcceptRA=no
Address=192.168.0.72/24
Gateway=192.168.0.1
DNS=192.168.0.1
```

Setting `net.addr6` adds a second `Address=` line and, if `net.gw6` is set, a
second `Gateway=`. Each entry in `net.dns` becomes its own `DNS=` line. The
exact file for the defaults is checked in under
[deb13-systemd-resolved/etc/](deb13-systemd-resolved/etc/).

Notes on the keys:

- `IPv6AcceptRA=no` stops the interface picking up a SLAAC address from
  router advertisements, so addressing stays fully static. Remove it if you
  want SLAAC alongside the static IPv4 address.
- `RequiredForOnline=yes` is the default for managed links and is written out
  only to make the intent explicit: `network-online.target` waits for this
  interface.

## Resolver Model

The `DNS=` servers are per-link settings consumed by systemd-resolved.
`/etc/resolv.conf` in the image is the stub symlink to
`/run/systemd/resolve/stub-resolv.conf`, so applications query resolved on
`127.0.0.53` and resolved forwards to the servers listed here. Do not list
`127.0.0.1` unless the image also runs a local resolver on port 53.

## Variables

See the table in [README.md](README.md#using-an-example). Example config:

```yaml
layer:
  base: trixie-minbase
  network: v3-net-config

net:
  addr: 10.0.0.5/24
  gw: 10.0.0.1
  dns: 10.0.0.1 1.1.1.1
```

## When to Use

- Headless hosts and appliances built on this base: it is the smallest change
  from what `trixie-minbase` already does.
- Environments that value deterministic unit files and `systemd-analyze`
  verification.
- Desktops usually run NetworkManager instead; see the built-in
  `network-manager` layer.

## Validate on the Device

```bash
systemd-analyze verify /etc/systemd/network/*.network
networkctl status eth0
ip route
resolvectl status eth0
ls -l /etc/resolv.conf
```

## References

- `systemd.network(5)`, `networkctl(1)`
- `systemd-resolved(8)`, `resolvectl(1)`, `resolv.conf(5)`
- RFC 1918 private IPv4 addressing
