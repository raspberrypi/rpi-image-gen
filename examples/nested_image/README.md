Build a system with a squashfs image that's resident in the rootfs and which gets mounted at boot.
There are a few different ways this could be accomplished.
Please make sure to install the dependencies required by the example.

```bash
examples/nested_image/
|-- config
|   `-- nested.yaml
|-- deps
|-- image
|   `-- embedded_squashfs
|       |-- main.cfg.in
|       |-- myimage.yaml
|       |-- pre-image.sh
|       |-- ro_assets.cfg.in
|       `-- writer.sh
`-- README.md
```

```bash
sudo ./install_deps.sh examples/nested_image/deps

rpi-image-gen build -S ./examples/nested_image/ -c nested.yaml
```
User password can be provided via cmdline args.
