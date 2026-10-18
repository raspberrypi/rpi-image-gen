# Debian Netplan Network (v2-net-config)

Static wired networking described in Netplan YAML and rendered by
systemd-networkd. In this directory it is example number 2 (v2).

## What the Layer Does

- Installs the `netplan.io` package. Nothing else is needed: the base image
  already runs systemd-networkd, which is the renderer this example uses.
- Writes `/etc/netplan/00-installer.yaml` with mode `0600`. Netplan refuses
  world-readable configuration files.
- Deletes `/etc/systemd/network/01-eth0.network`, the `DHCP=yes` unit that
  `rpi-device-base` installs. Netplan renders its own unit as
  `/run/systemd/network/10-netplan-eth0.network` at boot, and networkd uses
  the first matching unit in filename order, so the base file would otherwise
  win.

The layer runs after the device layer and after `systemd-net-min`
(`X-Env-Layer-AfterProvider: device,network-activator`), so the deletion is
guaranteed to happen after the file is created.

Netplan files are applied in lexical order. `00-` keeps this file first so
local definitions stay explicit.

## Generated File (defaults)

`/etc/netplan/00-installer.yaml`:

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: false
      dhcp6: false
      addresses:
        - 192.168.0.72/24
      routes:
        - to: default
          via: 192.168.0.1
      nameservers:
        addresses:
          - 192.168.0.1
```

Setting `net.addr6` adds a second entry under `addresses` and, if `net.gw6`
is set, a second default route. The exact file for the defaults is checked in
under [deb-netplan/etc/](deb-netplan/etc/).

Notes on the keys:

- `routes: - to: default` is the current way to express a default gateway.
  `gateway4` and `gateway6` still work but are deprecated in the Netplan
  reference.
- `ipv6-privacy` and `ipv6-address-generation` only matter for SLAAC-derived
  addresses. They are left out because this example assigns addresses
  statically.

## Renderer

`renderer: networkd` matches what `trixie-minbase` provides. Netplan can also
render to NetworkManager (`renderer: NetworkManager`), which suits desktops,
but that needs NetworkManager installed and managing the interface. The
built-in `network-manager` layer provides that; combining it with this
example is not covered here.

## Variables

See the table in [README.md](README.md#using-an-example). Example config:

```yaml
layer:
  base: trixie-minbase
  network: v2-net-config

net:
  addr: 10.0.0.5/24
  gw: 10.0.0.1
  dns: 10.0.0.1 1.1.1.1
```

## When to Use

- Fleets where one declarative YAML format should describe both server and
  desktop hosts.
- Provisioning pipelines that already generate Netplan.
- Not needed if you are happy writing systemd-networkd units directly; see
  [deb-systemd-resolved.md](deb-systemd-resolved.md).

## Validate on the Device

```bash
netplan get
netplan generate              # parses the YAML and reports problems
ls /run/systemd/network/      # expect 10-netplan-eth0.network
networkctl status eth0
resolvectl status eth0
```

## References

- Netplan reference: <https://netplan.readthedocs.io/>
- `netplan(5)`, `systemd.network(5)`
- RFC 1918 private IPv4 addressing
