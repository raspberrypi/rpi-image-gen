$(if $(PKG_NAME),, $(error PKG_NAME must be specified))
$(if $(PKG_VER),,  $(error PKG_VER must be specified))

$(if $(IGconf_sys_buildroot),,$(error IGconf_sys_buildroot is not defined))

DEB_BUILD_GNU_TYPE ?= $(shell dpkg-architecture -qDEB_BUILD_GNU_TYPE)
DEB_HOST_GNU_TYPE  ?= $(shell dpkg-architecture -qDEB_HOST_GNU_TYPE)

# Tools are built for build arch by default
PKG_BUILD_GNU_TYPE := $(or $(strip $(PKG_BUILD_GNU_TYPE)),$(DEB_BUILD_GNU_TYPE))
PKG_HOST_GNU_TYPE  := $(or $(strip $(PKG_HOST_GNU_TYPE)),$(DEB_BUILD_GNU_TYPE))

PKG_DEPS ?=
PKG_CTX ?=

# PKG_NAME may carry a group, eg mydir/mypkg
PKG_STEM := $(notdir $(PKG_NAME))

PKG_WORK_DIR := $(abspath $(IGconf_sys_buildroot)/$(PKG_CTX)/$(PKG_NAME)/$(PKG_HOST_GNU_TYPE))
PKG_SOURCE_STAMP := $(PKG_WORK_DIR)/$(PKG_STEM)-$(PKG_VER).source
PKG_PATCH_STAMP := $(PKG_WORK_DIR)/$(PKG_STEM)-$(PKG_VER).patch
PKG_BUILD_STAMP := $(PKG_WORK_DIR)/$(PKG_STEM)-$(PKG_VER).build
PKG_INSTALL_STAMP := $(PKG_WORK_DIR)/$(PKG_STEM)-$(PKG_VER).install
