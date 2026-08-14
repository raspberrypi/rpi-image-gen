#!/bin/sh

set -eu

rootfs="$1"

# Clean up stuff we don't need
rm -rf $1/etc/apt
rm -rf $1/etc/dpkg
rm -rf $1/usr/bin/dpkg
rm -rf $1/var/cache/*
