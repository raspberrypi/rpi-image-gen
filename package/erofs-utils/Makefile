PKG_NAME := erofs-utils
PKG_VER := 1.8.10
PKG_BUILD_SCHEME := autotools
PKG_DEPS := zstd util-linux
PKG_CONFIGURE_OPTS := \
   --with-libzstd \
   --without-selinux \
   --enable-multithreading \
   --disable-static \
   --disable-dependency-tracking \
   --disable-fuse
include ../shared/pkg.mk
