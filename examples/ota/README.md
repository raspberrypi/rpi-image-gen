Build an image that can be deployed remotely using Raspberry Pi Connect's experimental remote update capability.

This is a skeleton system that:

* Installs a minimal base Trixie OS
* Installs Raspberry Pi Connect Lite
* Installs and configures Raspberry Pi experimental OTA functionality

A device can auto-signin with Raspberry Pi Connect on first boot in one of two ways:

1. **Device identity** (Raspberry Pi Connect for Organisations only). The device authenticates using the unique identity in its OTP (one time programmable) memory. The identity must first be registered with your organisation via the [Raspberry Pi Connect Organisations Management API][management-api]. No credentials need to be embedded in the image:

   ```bash
   rpi-image-gen build -S ./examples/ota/ -c ota.yaml
   ```

2. **Auth key.** Embed a single-use auth key generated via your Raspberry Pi Connect dashboard:

   ```bash
   rpi-image-gen build -S ./examples/ota/ -c ota.yaml -- IGconf_connect_authkey=rpuak_XXX
   ```

If an auth key is embedded on a device that is also registered with an organisation, the auth key takes precedence.

For further details, see the [Raspberry Pi Connect documentation][connect-docs].

[management-api]: https://www.raspberrypi.com/documentation/services/connect.html#organisations-management-api
[connect-docs]: https://www.raspberrypi.com/documentation/services/connect.html
