Build a filesystem tarball and use it to create an arm64 Docker container base image with a customisable entry point. This uses a dynamic layer to create a base filesystem from a pinned Debian snapshot mirror, therefore making it reproducible. The resultant image is small and therefore ideal for publishing or downloadable use, CI pipelines, etc.

Build:
```bash
$ rpi-image-gen build -S ./examples/docker_export -c ./config/ci/arm64-rpi-trixie-slim.yaml
```

Or build specifying the timestamp for the Debian snapshot base:
```bash
$ rpi-image-gen build -S ./examples/docker_export -c ./config/ci/arm64-rpi-trixie-slim.yaml -- SOURCE_DATE_EPOCH=$(date -u -d "today 00:00" +%s)
```

This results in reproducible Debian Distribution packages installed in the base image. The image is set up so that apt can be run as normal to install packages from the rolling repositories.

File docker-arm64-rpi-trixie-slim.tar.gz can be published / distributed. To load and run locally:

```bash
$ docker load -i ./work/ci-images/docker-arm64-rpi-trixie-slim.tar.gz
Loaded image: localhost/raspberrypi/rpios:arm64-trixie-slim
```
```bash
$ docker run --rm -it localhost/raspberrypi/rpios:arm64-trixie-slim
root@d08093ff4649:/# echo $SHELL
/bin/bash
root@d08093ff4649:/#
```

rpi-image-gen creates `/usr/share/rpi-image-gen/origin` which describes the snapshot used.
