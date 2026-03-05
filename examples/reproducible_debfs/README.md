Build a reproducible Debian Trixie minbase filesystem tarball.

This example demonstrates using a custom dynamic layer to construct a filesystem base from a Debian Trixie snapshot. The dynamic layer uses a built-in generator to output apt compatible snapshot urls in the rendered layer YAML.

Normal layer cli commands function as usual, eg

```bash
$ rpi-image-gen layer -S ./examples/reproducible_debfs/ --describe example-minbase-snaphot

Layer: example-minbase-snaphot
Version: 1.0.0
Category: example
Description: Architecture agnostic Debian Trixie minbase snapshot
 providing a reproducible base.
Type: dynamic
Generator: envcp
Path: mylayer.yaml
```

Run the build to generate the base filesystem:

```bash
$ rpi-image-gen build -S ./examples/reproducible_debfs/ -c build.yaml
```

The resulting tarball can be exported as an OCI compatible archive suitable for running or publishing, etc.

```bash
$ podman import ./path/to/trixie-reproducible.tgz trixie:snapshot
Getting image source signatures
Copying blob fc50bbf8ecd0 done
Copying config d4014b11e8 done
Writing manifest to image destination
Storing signatures
sha256:d4014b11e8ab79c6e70123e9feab3ec76e76a78955577f089ed11f8d94214b69
$
$ podman image save --format oci-archive -o trixie-snap-oci.tar trixie:snapshot
Copying blob c6990d7e892d done
Copying config d4014b11e8 done
Writing manifest to image destination
Storing signatures
$
$ gzip trixie-snap-oci.tar
```

Publish or run...

```bash
$ podman image load -i ./trixie-snap-oci.tar.gz
Getting image source signatures
Copying blob 5c4c1ed5ed94 skipped: already exists
Copying config d4014b11e8 done
Writing manifest to image destination
Storing signatures
Loaded image: localhost/trixie:snapshot
$
$ podman run --rm -it localhost/trixie:snapshot /bin/bash
root@92b3c9432038:/# hostname
92b3c9432038
root@92b3c9432038:/# cat /etc/apt/sources.list
# Origin
# deb http://snapshot.debian.org/archive/debian/20251120T122224Z trixie main contrib non-free non-free-firmware
# deb http://snapshot.debian.org/archive/debian-security/20251120T122224Z trixie-security main contrib non-free non-free-firmware
deb http://deb.debian.org/debian trixie main contrib non-free non-free-firmware
deb http://deb.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
deb http://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware
root@92b3c9432038:/#
```

The filesystem base is reproducible. The layer cleanup phase configures APT for normal use so that any subsequent apt operations use the rolling repositories.
