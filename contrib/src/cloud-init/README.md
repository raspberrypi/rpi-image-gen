# cloud-init for rpi-image-gen

Sample skeleton for using cloud-init with rpi-image-gen.
Partially borrowed from the `pi-gen` cloud-init configuration.

## Usage

1. Fill in the applicable details in the `config/pi-cloud-init.yaml`.
2. Build and provision the image as usual.
3. On a FAT32 formatted USB drive with exactly the label `CIDATA`, add
   `meta-data`, `network-config`, and `user-data`. The details of
   what should be in those files can be found at
   <https://cloudinit.readthedocs.io/>, with sample files in this repo
   under the directory `NoCloud-USB`.
