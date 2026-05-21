Build an image that can be deployed remotely using Raspberry Pi Connect's experimental remote update capability.

This is a skeleton system that:

* Installs a minimal base Trixie OS
* Installs Raspberry Pi Connect Lite
* Installs and configures Raspberry Pi experimental OTA functionality

One of the by-products of the build is `update.tar.zst` located under `work/image-myapp/` which can be deployed to the device via Raspberry Pi Connect to update it.

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

## Wireless Networking

The minimal base Trixie OS enables wired and wireless networking by default. To have the device associate to a wireless AP automatically on boot using WPA2, pre-seed an iwd profile by adding the following to `examples/ota/config/ota.yaml`:

```yaml
iwd:
  profile: ${@SRCROOT}/<My SSID>.psk

ieee80211:
  regdom: GB
```

Where the profile contains:
```bash
[Security]
Passphrase=<my secret passphrase>
```

Place `<My SSID>.psk` directly under `examples/ota/` - rpi-image-gen sets that as its source directory for this example, so `${@SRCROOT}` resolves there. Set `ieee80211.regdom` to the ISO 3166-1 alpha-2 country code for your region.

The profile will be retained across AB slot rotations.

For further details see the [iwd layer documentation][iwd-docs].

[management-api]: https://www.raspberrypi.com/documentation/services/connect.html#organisations-management-api
[connect-docs]: https://www.raspberrypi.com/documentation/services/connect.html
[iwd-docs]: https://raspberrypi.github.io/rpi-image-gen/layer/iwd.html
