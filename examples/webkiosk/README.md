Build an image which automatically boots into kiosk mode to run an web application on Wayland.

This is a very simple system which includes one of the built-in config files, overrides some settings and uses a custom layer to:

* Install a set of packages over and above those provided by the base which are needed to run the kiosk
* Install and enable a systemd service to automatically run the kiosk at boot up

It also uses the AB image layout to support switching between slots should upgrade functionality be included.

Note: This relies on the built-in configuration included by kiosk.yaml. Including this file is not necessary if kiosk.yaml specifies all attributes/layers.
To deploy a production kiosk system it is envisaged that a specific config file would be used, therefore giving full control over the base system to the developer.

Usage of `-S` allows rpi-image-gen to locate the config file automatically because the source directory (`./examples/webkiosk/`) is prioritised in the search path.

```bash
rpi-image-gen build -S ./examples/webkiosk/ -c kiosk.yaml
```
