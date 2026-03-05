$(if $(PKG_NAME),, $(error PKG_NAME must be specified))
$(if $(PKG_VER),,  $(error PKG_VER must be specified))

$(if $(IGconf_sys_buildroot),,$(error IGconf_sys_buildroot is not defined))

PKG_DEPS ?=
PKG_CTX ?=

PKG_WORK_DIR := $(abspath $(IGconf_sys_buildroot)/$(PKG_CTX)/$(PKG_NAME))
PKG_SOURCE_STAMP := $(PKG_WORK_DIR)/$(PKG_NAME)-$(PKG_VER).source
PKG_PATCH_STAMP := $(PKG_WORK_DIR)/$(PKG_NAME)-$(PKG_VER).patch
PKG_BUILD_STAMP := $(PKG_WORK_DIR)/$(PKG_NAME)-$(PKG_VER).build
PKG_INSTALL_STAMP := $(PKG_WORK_DIR)/$(PKG_NAME)-$(PKG_VER).install
