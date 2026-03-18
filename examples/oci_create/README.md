Build a filesystem tarball and create an OCI compatible container base image from it for arm64. This uses a dynamic layer to create a base filesystem from a pinned Debian snapshot mirror, therefore making it reproducible. The resultant image is small and therefore ideal for publishing or downloadable use, CI pipelines, etc.

Build:
```bash
$ rpi-image-gen build -S ./examples/oci_create -c ./config/ci/arm64-rpi-trixie-slim.yaml
```

Or build specifying the timestamp for the Debian snapshot base:
```bash
$ rpi-image-gen build -S ./examples/oci_create -c ./config/ci/arm64-rpi-trixie-slim.yaml -- SOURCE_DATE_EPOCH=$(date -u -d "today 00:00" +%s)
```

This results in reproducible Debian Distribution packages installed in the base image. The image is set up so that apt can be run as normal to install packages from the rolling repositories.

File oci-arm64-rpi-rpios-trixie-slim.tar.gz can be published / distributed. To load and run locally:

```bash
$ podman load -i ./work/ci-images/oci-arm64-rpi-rpios-trixie-slim.tar.gz
Getting image source signatures
Copying blob 646fb9ee0731 done
Copying config 9773f20fc7 done
Writing manifest to image destination
Storing signatures
Loaded image: localhost/raspberrypi/rpios:arm64-trixie-slim
```
```bash
$ podman run --rm -it localhost/raspberrypi/rpios:arm64-trixie-slim /bin/bash
root@c6a98bd97537:/# cat /usr/share/rpi-image-gen/origin
# Layer: base-minbase-snapshot
# Source: trixie-snapshot.sources
# Snapshot origin: 20260318T000000Z
# SOURCE_DATE_EPOCH: 1773792000
root@c6a98bd97537:/# apt update
Get:1 http://deb.debian.org/debian trixie InRelease [140 kB]
...
```

rpi-image-gen creates `/usr/share/rpi-image-gen/origin` which describes the snapshot used. The container can be inspected after loading, too:

```bash
$ podman inspect localhost/raspberrypi/rpios:arm64-trixie-slim
```

The above uses podman, but docker works just as well.

Note: If using docker you may need to enable containerd snapshotter so the Docker daemon can understand the OCI format. Adding the following to /etc/docker/daemon.json is one way to do this:
```json
{
  "features": {
    "containerd-snapshotter": true
  }
}

```
See https://docs.docker.com/engine/storage/containerd/
