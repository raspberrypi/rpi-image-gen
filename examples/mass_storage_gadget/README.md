Build a microboot image that presents the board's storage to a host machine as
USB mass storage, with a serial console on the same cable. Useful for flashing
or imaging a board from a PC.

Note: Mass storage gadget images from pi-gen-micro and usbboot also expose
device storage to the host in equivalent ways. This example just demonstrates
how to use rpi-image-gen and its microboot layer to achieve the same result.

```bash
rpi-image-gen build -S ./examples/mass_storage_gadget/ -c pi5-gadget.yaml
```

The output is a bare FAT filesystem image with no partition table, produced by
`image-bootfs`. Sending it to a device using `rpiboot` loads it into RAM.

## How it's put together

**The device layer supplies the kernel.** The base layer installs none, so the
responsibility of providing kernel and firmware resides here. For Pi5/CM5
no VC firmware is required. `linux-image-rpi-v8` or `linux-image-rpi-2712`
will yield a successful kernel boot. Pi4/CM4 and other Armv8 devices require
the v8 kernel and VC firmware.

**The gadget layer extends the initramfs, two different ways.**

Modules go through the list sweep. The base layer scans the build plan for
`modules.list` and `initramfs.list.<initsys>` fragments shipped beside any
layer's own metadata and appends them to its own lists, so `modules.list` only
names what this image adds.

The init script does not reside in the donor chroot so must be supplied via
a hook. Shipped content goes straight into `$1/staging`, which the base syncs
into the initramfs root automatically.

The base layer's default `config.txt` is replaced with a file written by the
gadget layer to add `dtoverlay=dwc2,dr_mode=peripheral`. Without this, there is
no device controller for the gadget to bind and nothing would appear on the host.

**`S60gadget` builds the gadget at boot.**

This mounts configfs, creates one LUN per block device that exists, adds a
CDC-ACM function for the console, and binds whichever controller the board
exposes - the UDC is probed from `/sys/class/udc`.

## A note on the console

`usb-autologin` is the console profile used. This drops to a root shell
automatically. This console mode is not recommended for all use cases.
