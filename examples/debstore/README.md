Build a system with a custom YAML layer to install locally stored Debian packages in the chroot.

```text
examples/debstore/
|-- config
|   `-- deb12-store.yaml
|-- layer
|   `-- debstore-installer.yaml
|-- pkgs
`-- README.md
```

First, copy the .deb files to examples/debstore/pkgs then:

```bash
rpi-image-gen build -S ./examples/debstore/ -c deb12-store.yaml
```
