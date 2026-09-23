Build an A/B image with signed boot slots, for devices running secure boot.

Configuring `image.signcmd` is the only change needed. `image-rota` signs each
boot slot (`boot.img`), with a detached signature `boot.sig` beside it.

## Signing keys

Read this before generating one.

The private key is the root of trust for every device it signs for. Anyone
holding it can produce images those devices will boot. Its public key hash is
written to one-time-programmable memory when a device is provisioned and cannot
be changed afterwards.

- Never commit a private key, and never leave one on a shared or
  general-purpose build machine. `keys/` here is gitignored, for trial use only.
- Use an HSM or smartcard for anything real. `rpi-eeprom-digest -k` accepts a
  PKCS#11 URI and `-H` a signing wrapper, so the key need not exist as a file.
- Restrict and log who may invoke the signing command. rpi-image-gen passes it
  the image, its size and an output path, nothing more - where the key comes
  from, and who may use it, is that command's business.
- Sign on a dedicated host. A machine that builds untrusted code is not one.

Secure boot requires a 2048-bit RSA key. No other type or size is accepted.
For a trial only:

```bash
mkdir -p examples/signed_ota/keys
openssl genrsa -out examples/signed_ota/keys/private.pem 2048
openssl rsa -in examples/signed_ota/keys/private.pem -pubout \
   -out examples/signed_ota/keys/public.pem
```

## Build

```bash
rpi-image-gen build -S ./examples/signed_ota/ -c signed-ota.yaml
```

Output is the disk image, an IDP archive and an OTA bundle
`signed-ota.update.tar.zst`. The boot slot inside the bundle is signed by the
same key used at provisioning, so an update applied in the field verifies on
the next boot.

`boot.img` is byte-identical between builds sharing a `SOURCE_DATE_EPOCH`, so
the same source signs to the same signature. Pass it explicitly for anything you
intend to reproduce. The partition table and root filesystem are not reproducible.

Verification of the signing command can be performed cryptographically using the
same suite as the example signing wrapper:

```bash
$ rpi-eeprom-digest -i ./work/image-signed-ota/boot.img \
   -k ./examples/signed_ota/keys/public.pem \
   -v ./work/image-signed-ota/boot.sig
Verified OK
```

## Device provisioning

The device must be provisioned with the public key and have secure boot enabled.
Until then, the image boots but the signature is not checked.

## OTA

See `examples/ota` for information about how the update can be delivered to the
device over Raspberry Pi Connect.

Further information can be found in the [rpi-sb-provisioner][provisioner] and
[usbboot][usbboot] tooling documentation.

[provisioner]: https://github.com/raspberrypi/rpi-sb-provisioner
[usbboot]: https://github.com/raspberrypi/usbboot/blob/master/docs/secure-boot.md
