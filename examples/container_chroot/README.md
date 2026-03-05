Build a filesystem tarball containing development utilities for the host architecture, import it into a container, and use the container to build a program using GNU autotools.  

This demonstrates an alternative use case for rpi-image-gen where no disk image is created. The build output is a filesystem tarball that is device-agnostic (containing no kernel, boot firmware, or device-specific components) and includes only binaries matching the host machine's architecture. The resulting container provides a completely self-contained build environment that can be reused for development purposes. This approach effectively creates a 'build chroot' suitable for software development workflows.  

SBOM and deploy layers are intentionally omitted from this particular example. If this functionality was desired, the appropriate layer(s) could simply be added to the layer section in the config file.

```text
examples/container_chroot/
|-- config
|   `-- host-build.yaml
|-- layer
|   `-- build-tools.yaml
`-- README.md
```

```bash
# Build the fs tarball described by our custom layer
$ rpi-image-gen build -S ./examples/container_chroot -c host-build.yaml

# Use podman (or docker) to import it
$ podman import ./work/mydev/chroot.tgz my-chroot:latest

# Run it and start a shell
$ podman run -it my-chroot:latest /bin/bash
...
root@2162eedf01af:/# echo hello, world
hello, world
root@2162eedf01af:/# apt update
...
# Fetch example program, build, install and run
# wget https://ftp.gnu.org/gnu/hello/hello-2.12.tar.gz
# tar xzf ./hello-2.12.tar.gz
# cd hello-2.12
# ./configure
# make
# make install
# hello
# exit

# Now back on the host and outside the container

# Show what we have
$ podman ps -a
...

# Delete the container
$ podman rm <container id>

# Delete the image
$ podman rmi my-chroot:latest
```
