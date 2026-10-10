# Example Networks

Community-contributed examples of static wired networking for rpi-image-gen,
one per common Linux network stack. As with everything under `contrib/`, they
are provided on a best-effort basis and may lag the core project.

The three examples are:

| Example directory        | Layer           | Stack                                       | Package added | File written                              |
|--------------------------|-----------------|---------------------------------------------|---------------|-------------------------------------------|
| `deb-interfaces`         | `v1-net-config` | ifupdown                                    | `ifupdown`    | `/etc/network/interfaces`                 |
| `deb-netplan`            | `v2-net-config` | Netplan, rendered by systemd-networkd       | `netplan.io`  | `/etc/netplan/00-installer.yaml`          |
| `deb13-systemd-resolved` | `v3-net-config` | systemd-networkd unit, DNS via systemd-resolved | none      | `/etc/systemd/network/01-eth0.network`    |

"v1", "v2" and "v3" are example numbers, not versions of one layer. Each layer
is a complete, independent example. See the per-example notes in
[deb-interfaces.md](deb-interfaces.md), [deb-netplan.md](deb-netplan.md) and
[deb-systemd-resolved.md](deb-systemd-resolved.md).

## What the Base Image Already Provides

The examples are written against the `trixie-minbase` suite layer. Knowing what
that base sets up explains most of what each example has to do:

- `systemd-net-min` installs and enables systemd-networkd and, through
  `systemd-resolved`, the systemd DNS stub resolver.
- `rpi-device-base` (pulled in by every Raspberry Pi device layer) writes
  `/etc/systemd/network/01-eth0.network` with `DHCP=yes`, and a matching unit
  for `wlan0`.
- `iwd` is installed for Wi-Fi. The examples leave Wi-Fi alone.

So a fresh `trixie-minbase` image already brings `eth0` up with DHCP under
systemd-networkd. A static example therefore has to **take `eth0` over** from
that unit, not just drop a file into place:

- `v1-net-config` replaces `01-eth0.network` with one that marks the interface
  `Unmanaged=yes`, so ifupdown alone configures it.
- `v2-net-config` deletes `01-eth0.network`. Netplan renders its own unit into
  `/run/systemd/network/` at boot, and the base file would otherwise sort first
  and win.
- `v3-net-config` overwrites `01-eth0.network` with the static configuration.
  Same filename, so it simply replaces the DHCP unit.

All three declare `X-Env-Layer-AfterProvider: device,network-activator`, which
makes rpi-image-gen order them after the device layer and after
`systemd-net-min`, so the replacement is deterministic rather than a happy
accident of plan order.

## One Stack per Image

Choose one example per image. Mixing stacks for the same interface produces
ordering races and duplicate state that are hard to diagnose.

Every example layer declares `X-Env-Layer-Provides: wired-static-config`. A
capability may only be provided by one layer in a build, so rpi-image-gen
refuses a plan that contains two of these examples with a "Provider conflict"
error. The layers also list each other in `X-Env-Layer-Conflicts` to document
the intent.

## Using an Example

Point `-S` at the example directory and name the layer in your config. All
three layers accept the same variables under the `net` prefix:

| Config key   | Variable            | Default           | Meaning                                              |
|--------------|---------------------|-------------------|------------------------------------------------------|
| `net.iface`  | `IGconf_net_iface`  | `eth0`            | Interface the static configuration applies to        |
| `net.addr`   | `IGconf_net_addr`   | `192.168.0.72/24` | IPv4 address in CIDR notation                        |
| `net.gw`     | `IGconf_net_gw`     | `192.168.0.1`     | IPv4 default gateway                                 |
| `net.dns`    | `IGconf_net_dns`    | `192.168.0.1`     | Space separated DNS servers, in preference order     |
| `net.addr6`  | `IGconf_net_addr6`  | empty             | Optional IPv6 address in CIDR notation               |
| `net.gw6`    | `IGconf_net_gw6`    | empty             | Optional IPv6 default gateway, used only with addr6  |

A config file:

```yaml
device:
  layer: rpi5

image:
  layer: image-rpios
  name: my-static-host

layer:
  base: trixie-minbase
  network: v3-net-config

net:
  addr: 10.0.0.5/24
  gw: 10.0.0.1
  dns: 10.0.0.1 1.1.1.1
  addr6: 2001:db8:1::5/64
  gw6: 2001:db8:1::1
```

```bash
rpi-image-gen build -S contrib/net/example-networks/deb13-systemd-resolved -c my-static-host.yaml
```

Any variable can also be overridden on the command line after `--`, for
example `-- IGconf_net_addr=10.0.0.9/24`.

Leaving `addr6` empty gives an IPv4-only interface. The examples do not accept
router advertisements, so there is no SLAAC address either. Set `addr6` (and
usually `gw6`) to add a static IPv6 address.

Only list `127.0.0.1` in `dns` if the image also installs a local resolver.
With systemd-resolved as the stub resolver, nothing listens on port 53 of
`127.0.0.1`; resolved itself listens on `127.0.0.53`. The examples default to
the gateway address, which is right for most home and small office routers.

## Reference /etc Trees

The `etc/` directory under each example holds exactly the files the layer
writes with the default variables. They are there to read and compare, and
they are not copied into the image. If you change a layer's hook, regenerate
them so they stay honest.

The top-level `reference/` directory holds hand-written examples of related
files that none of the layers produce. They are illustrative only:

- `reference/networks` is a sample `/etc/networks`, the historical network
  name table read by tools such as `route`. Debian trixie no longer ships this
  file in `netbase`, and nothing in these examples needs it.
- `reference/01-network-manager-all.yaml` is the Netplan drop-in that hands
  every device to NetworkManager. It is what a desktop image would use instead
  of `renderer: networkd`, and it requires NetworkManager to be installed, for
  example through the built-in `network-manager` layer. It is not part of the
  `deb-netplan` example.

## Run the Example Verifier

`run-example-layers.sh` builds each example on top of `trixie-minbase` for a
Pi 5 and checks the resulting filesystem. It needs a host that can run
rpi-image-gen builds (see the project README and `install_deps.sh`).

```bash
./run-example-layers.sh                       # all three examples
./run-example-layers.sh deb-netplan           # just one
./run-example-layers.sh -- IGconf_net_addr=10.0.0.5/24 IGconf_net_gw=10.0.0.1
```

For each example it writes a config into a time-stamped work root under
`build/<example>/run-<stamp>/`, runs `rpi-image-gen build -f` (filesystem
only, no image, SBOM disabled), locates the target filesystem from the
build's `bootstrap/final.env`, and asserts:

| Example                  | Checks                                                                                                    |
|--------------------------|-----------------------------------------------------------------------------------------------------------|
| `deb-interfaces`         | `ifupdown` installed, `networking.service` enabled, static stanza and `dns-nameservers` present, `01-eth0.network` says `Unmanaged=yes` |
| `deb-netplan`            | `netplan.io` installed, YAML has `renderer: networkd` and `dhcp4: false`, file mode is `0600`, `01-eth0.network` is gone |
| `deb13-systemd-resolved` | networkd and resolved enabled, `01-eth0.network` has `DHCP=no`, `Address=` and `DNS=`                      |

Exit status is 0 when every selected build and check passes, 1 otherwise.
`build/` is ignored by git.

Each work root is fresh, so rpi-image-gen compiles its host tools (bdebstrap,
genimage, zstd) once per run before the filesystem build begins. Expect that
overhead on every invocation.

## Validate on the Device

After booting an image, confirm the stack is doing what you expect with its
native tools:

| Stack             | Commands                                                                 |
|-------------------|--------------------------------------------------------------------------|
| ifupdown          | `ifquery --list`, `ifquery eth0`, `networkctl status eth0` (should say unmanaged) |
| Netplan           | `netplan get`, `netplan generate`, `networkctl status eth0`              |
| systemd-networkd  | `networkctl status eth0`, `systemd-analyze verify /etc/systemd/network/*.network` |
| Resolver, all     | `resolvectl status`, `ls -l /etc/resolv.conf`, `ip route`                |

## Choosing a Stack

| Stack                        | Headless or server | Desktop                      | Notes                                                                                     |
|------------------------------|--------------------|------------------------------|-------------------------------------------------------------------------------------------|
| ifupdown (`v1`)              | Good fit           | Limited                      | Smallest and most predictable; classic Debian. No desktop integration.                    |
| Netplan (`v2`)               | Good fit           | Good with NetworkManager renderer | Declarative YAML; the same file can target networkd or NetworkManager.               |
| systemd-networkd (`v3`)      | Good fit           | Conditional                  | Nothing extra to install on this base. Desktop use needs coordination with NetworkManager. |

Whatever the environment, keep addressing, gateway and DNS policy in one
authoritative place, match interfaces deterministically, and validate the
generated configuration with the stack's own tools before deploying.

## References

- contrib scope and support model: [../../README.adoc](../../README.adoc)
- rpi-image-gen layers and variables: `docs/layer/index.adoc`, `docs/config/index.adoc`
- interfaces format: `interfaces(5)`
- Netplan reference: <https://netplan.readthedocs.io/>
- systemd network units: `systemd.network(5)`
- resolver: `systemd-resolved(8)`, `resolv.conf(5)`
- private IPv4 addressing: RFC 1918
- IPv6 documentation prefix `2001:db8::/32`: RFC 3849

This contribution was contributed by devopsbob of Kranson Enterprises,
Michigan, USA, for community review and upstream consideration.
