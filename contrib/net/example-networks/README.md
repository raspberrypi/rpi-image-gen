# Example Networks

This directory contains community-contributed networking examples for rpi-image-gen.

These examples are intended for evaluation, adaptation, and testing. As with other content under contrib, they are provided on a best-effort basis and may require updates as upstream layers evolve.

## Scope and Intent

The examples demonstrate three common Linux networking approaches on Debian-based images:

1. deb-interfaces using ifupdown-style configuration in /etc/network/interfaces
2. deb-netplan using Netplan YAML in /etc/netplan/00-installer.yaml
3. deb13-systemd-resolved using systemd-networkd units in /etc/systemd/network/01-eth0.network

Choose one primary network stack per image when possible. Mixing multiple configuration stacks in the same image can produce ordering conflicts, duplicate state, and hard-to-diagnose behavior.

The checked-in /etc paths under each example directory are intentional reference examples. They are provided to help users identify which final filesystem paths are targeted by build-time verification checks.

## Compatibility Matrix

| Stack                                                | Headless | Server   | Desktop         | Notes                                                                                                |
|------------------------------------------------------|----------|----------|-----------------|------------------------------------------------------------------------------------------------------|
| deb-interfaces (ifupdown)                            | Good fit | Good fit | Limited fit     | Minimal and predictable; common for static server-style setups.                                      |
| deb-netplan                                          | Good fit | Good fit | Good fit        | Flexible YAML model; commonly used where desktop integration tooling is expected.                    |
| deb13-systemd-resolved (systemd-networkd + resolved) | Good fit | Good fit | Conditional fit | Lightweight and service-oriented; desktop use may require coordination with NetworkManager policies. |

## Contrib Alignment

This folder follows the contrib/net purpose described in contrib/README.adoc:

1. It provides networking-specific additions as optional examples.
2. It is not required for core rpi-image-gen functionality.
3. It should be treated as reference material that may lag mainline changes.

When contributing updates here, prefer small, reviewable changes and avoid embedding secrets or environment-specific credentials.

This contribution is contributed by devopsbob of Kranson Enterprises, Michigan, USA, for community review and upstream consideration.

## Run the Example Verifier

Use the driver script to build each example layer independently and verify expected output files.

Command:

./run-example-layers.sh

The script runs three builds:

1. deb-interfaces with v1-net-config
2. deb-netplan with v2-net-config
3. deb13-systemd-resolved with v3-net-config

Verification checks:

1. v1 verifies /etc/network/interfaces contains iface eth0 inet static
2. v2 verifies /etc/netplan/00-installer.yaml contains ethernets:
3. v3 verifies /etc/systemd/network/01-eth0.network contains DHCP=no

These checks validate target paths in the generated image filesystem. The repository copies of files under each example's /etc tree are guidance artifacts for learning and comparison.

Exit codes:

1. 0 means all builds and checks passed
2. 1 means one or more builds or checks failed

## Linux and Open-Source Networking Standards

These examples align with widely used Linux networking conventions and open-source tooling interfaces:

1. ifupdown conventions for interface declarations in /etc/network/interfaces
2. Netplan schema-driven YAML for network definitions
3. systemd-networkd unit model via .network files
4. resolver behavior managed through systemd-resolved where enabled

Operational guidance:

1. Keep addressing, gateway, and DNS policy in a single authoritative stack.
2. Use deterministic interface matching and explicit static settings for headless systems.
3. Validate generated config with native tools before deployment.
4. Document local overrides if combining stack components is unavoidable.

## Deployment Guidance by Environment Size

The same stack can be used in many places, but operational priorities differ by environment.

1. Personal home:
Prefer simple static or DHCP-centric layouts. Keep one clear DNS policy and document local router or resolver assumptions.
2. Small business:
Use explicit addressing plans, reproducible host naming, and clear rollback steps. Standardize one stack per device class.
3. Large enterprise:
Use declarative configuration with strict change control, inventory-driven addressing, and integration with central DNS/NTP/security controls.

## Quick Validation Checklist

After generating an image, validate with native tools:

1. interfaces: ifquery --list and ifquery eth0
2. netplan: netplan generate and netplan get
3. systemd-networkd: networkctl status and systemd-analyze verify /etc/systemd/network/*.network
4. resolver path: resolvectl status and ls -l /etc/resolv.conf

## References

1. contrib scope and support model: ../README.adoc
2. interfaces format: man 5 interfaces
3. Netplan format and behavior: <https://netplan.readthedocs.io/>
4. systemd network units: man 5 systemd.network
5. resolver service behavior: man 8 systemd-resolved and man 5 resolv.conf
6. private IPv4 addressing: RFC 1918
7. IPv6 SLAAC: RFC 4862
8. unique local IPv6 addresses: RFC 4193
