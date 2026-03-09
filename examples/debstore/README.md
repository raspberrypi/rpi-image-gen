Build a system with a custom YAML layer to install locally stored Debian packages in the chroot.

> **Note:** For most use cases, local `.deb` files and apt packages can be installed directly via a
> `[packages]` config section without a custom layer. See the configuration documentation for
> details. This example remains useful if you need finer control over the installation process.

For example, to install a local package and one from a remote repository, use the following config file addition:

```yaml
packages:
  - pkgs/mypkg_1.0_arm64.deb
  - curl
```

```text
examples/debstore/
|-- config
|   `-- deb-store.yaml
|-- layer
|   `-- debstore-installer.yaml
|-- pkgs
`-- README.md
```

First, copy the .deb files to examples/debstore/pkgs then:

```bash
rpi-image-gen build -S ./examples/debstore/ -c deb-store.yaml
```
