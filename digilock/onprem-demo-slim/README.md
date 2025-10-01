Build a small system with minimum base packages and trimmed down packages to boot on a Raspberry Pi family 5 device only.

Contains custom device and image layers and demonstrates how to communicate the location of device and image specific assets, hooks, etc.

```text
examples/slim/
|-- config
|   `-- pi5-slim.yaml
|-- device
|   `-- mypi5
|       |-- cmdline.txt
|       |-- config.txt
|       |-- device
|       |   `-- rootfs-overlay
|       |       |-- boot
|       |       |   `-- firmware
|       |       |       `-- cmdline.txt
|       |       `-- etc
|       |           `-- fstab
|       |-- myboard.yaml
|       `-- post-build.sh
|-- image
|   `-- compact
|       |-- genimage.cfg.in
|       |-- myimage-layout.yaml
|       `-- pre-image.sh
|-- layer
|   |-- slim-customisations.yaml
|   `-- slim.yaml
`-- README.md
```

```bash
rpi-image-gen build -S ./examples/slim/ -c pi5-slim.yaml
```
