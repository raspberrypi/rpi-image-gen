PKG_NAME := erofs-utils
EROFS_UTILS_VER ?= 1.9.4
PKG_VER := $(EROFS_UTILS_VER)
PKG_BUILD_SCHEME := autotools
PKG_DEPS := zstd util-linux
PKG_CONFIGURE_OPTS := \
   --with-libzstd \
   --without-selinux \
   --enable-multithreading \
   --disable-static \
   --disable-dependency-tracking \
   --disable-fuse \
   MAX_BLOCK_SIZE=16384
include ../shared/pkg.mk
