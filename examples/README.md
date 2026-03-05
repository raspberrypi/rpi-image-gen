# rpi-image-gen examples

A collection of examples to demonstrate rpi-image-gen and to help jump-start projects. Please refer to the README in each example directory for further details.  

Since images are created with user login disabled by default (see layer file device-base.yaml, or `rpi-image-gen layer --describe device-base`), unless otherwise indicated in the example information, the example will not yield an image allowing you to login. If you need to be able to log into a system running the image created by the example you'll need to specify a password (either in the config file or via the command line), or utilise SSH. For example:  

```bash
# Specify password on the command line
$ rpi-image-gen build <args> -- IGconf_device_user1pass=<password>

# To ensure the shell doesn't expand any special characters, enclose in single quotes
$ rpi-image-gen build <args> -- IGconf_device_user1pass='Fo0bar!!'

# Specify password in the config file
device:
  user1pass: <password>

# If the image supports SSH access, and a password has been specified, SSH login will be possible for that user.
# To lock that down by enforcing SSH public key authentication with a known key only, and to prevent other login routes
$ rpi-image-gen build <args> -- 'IGconf_ssh_pubkey_user1=$(< ~/.ssh/id_rsa.pub)' IGconf_ssh_pubkey_only=y

# ..or via config file
ssh:
  pubkey_user1: $(< ${HOME}/.ssh/id_rsa.pub)
  pubkey_only: y
```
Obviously, storing passwords in cleartext is incredibly bad practice. The above serves as demonstration only.
