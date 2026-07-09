Build a system with a custom config and multiple layers, declaring dependencies between layers and defining variables.

The config file used by this example specifies a custom layer to build a system from, which uses built-in and custom layers as dependencies. The custom layers declare additional variables to the config system which are used in the layers.

Layer acme-sdk-v1.yaml uses the uchroot helper to simplify user chroot operations to ensure files are created in the user's home directory with appropriate permissions. The helper makes standard system variables available in the environment which abstracts and simplifies the operation.

The trait/ directory demonstrates custom traits, building up a small hierarchy under hw:acme. hw.deb822 extends the built-in hw namespace (via its own Include:, adding to it rather than replacing it) with a sub-namespace, hw:acme, holding this vendor's own components (hw:acme:can, hw:acme:gps), a board descriptor (hw:acme:carrierv1), and a product descriptor (hw:acme:productv1):

- hw:acme:can and hw:acme:gps each Triggers: the corresponding existing built-in generic trait (hw:can, hw:gps) - the activation responsibility lives on the specific component, not on whatever selects it, the same way hw:bluetooth:broadcom's presence implies hw:bluetooth.
- hw:acme:carrierv1 Requires: an existing built-in token (hw:device:rpi:cm5-lite) and Triggers: its own two components - showing a custom trait can both depend on and activate built-in tokens by name, without redeclaring them.
- hw:acme:productv1 Triggers: both carrierv1 and hw:device:rpi:cm5-lite directly, completing the picture: declaring just the product cascades all the way down through the carrier, its components, the generic hw:can/hw:gps traits, and the entire built-in device chain (SoC, storage, wlan, bluetooth, boot).

Keeping custom traits under their own vendor sub-namespace (hw:acme:*) rather than adding them directly as new top-level hw:* siblings avoids ever colliding with a same-named token the built-in registry might add later.

```text
examples/custom_layers/
|-- acme.options
|-- config
|   `-- acme-integration.yaml
|-- layer
|   |-- acme-developer.yaml
|   |-- acme-sdk-v1.yaml
|   `-- essential.yaml
|-- profile
|   `-- deb12-acme
|-- trait
|   |-- hw
|   |   |-- acme
|   |   |   `-- board.deb822
|   |   `-- acme.deb822
|   `-- hw.deb822
|-- README.md
`-- setup-functions
```

```bash
rpi-image-gen build -S ./examples/custom_layers/ -c acme-integration.yaml
```

```bash
# Inspect the custom traits, combined with the built-in registry:
rpi-image-gen config --srcroot ./examples/custom_layers --trait=hw:acme
```
