Build an image that can be deployed remotely using Raspberry Pi Connect's
experimental remote update capability.

This is a skeleton system that:

* Installs a minimal base Trixie OS
* Installs Raspberry Pi Connect Lite, configured with a given auth key
* Installs and configures Raspberry Pi experimental OTA functionality

```bash
rpi-image-gen build -S ./examples/ota/ -c ota.yaml -- IGconf_connect_authkey=rpuak_XXX
```
