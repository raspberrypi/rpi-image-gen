PKG_SHARED_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
include $(PKG_SHARED_DIR)/pkg-env.mk

DEB_BUILD_GNU_TYPE ?= $(shell dpkg-architecture -qDEB_BUILD_GNU_TYPE)
DEB_HOST_GNU_TYPE  ?= $(shell dpkg-architecture -qDEB_HOST_GNU_TYPE)

# Tools are built for build arch by default
PKG_BUILD_GNU_TYPE := $(or $(strip $(PKG_BUILD_GNU_TYPE)),$(DEB_BUILD_GNU_TYPE))
PKG_HOST_GNU_TYPE  := $(or $(strip $(PKG_HOST_GNU_TYPE)),$(DEB_BUILD_GNU_TYPE))

PKG_DESTDIR         ?= $(abspath $(IGconf_sys_buildroot)/staging/$(PKG_HOST_GNU_TYPE))
PKG_RUNTIME_DESTDIR ?= $(abspath $(IGconf_sys_buildroot)/host/$(PKG_HOST_GNU_TYPE))
PKG_PREFIX          ?= /usr
PKG_CACHE_ROOT      := $(abspath $(if $(strip $(IGconf_sys_cachedir)),$(IGconf_sys_cachedir),/tmp))

PKG_INSTALL_PATH := $(abspath $(PKG_DESTDIR)/$(PKG_PREFIX))
PKG_RUNTIME_PATH := $(abspath $(PKG_RUNTIME_DESTDIR)/$(PKG_PREFIX))

THIS_PKG ?= $(CURDIR)

PKG_META ?= $(PKG_NAME)-$(PKG_VER).meta
PKG_META_PATH := $(abspath $(THIS_PKG)/$(PKG_META))
ifeq (,$(wildcard $(PKG_META_PATH)))
$(error $(PKG_META_PATH) not found)
endif

PKG_META_PATH := $(abspath $(CURDIR)/$(PKG_META))
PKG_SOURCE_DIR ?= $(PKG_NAME)-$(PKG_VER)
PKG_ARCHIVE ?= $(PKG_NAME)-$(PKG_VER).tar.gz
PKG_SUBDIR ?= .

PKG_ENVIRONMENT    ?=
PKG_BUILD_SCHEME   ?=
PKG_PATCH_DIR      ?= patches/$(PKG_VER)
PKG_PATCHES        := $(sort $(wildcard $(abspath $(THIS_PKG)/$(PKG_PATCH_DIR))/*.patch))
PKG_PATCH_STRIP    ?= 1
PKG_UNPACK_STRIP   ?= 1
PKG_CONFIGURE_OPTS ?=
PKG_LIB_SHARED     ?= lib$(patsubst lib%,%,$(PKG_NAME))*.so*

PKG_CPPFLAGS ?= -I$(PKG_INSTALL_PATH)/include
PKG_CFLAGS   ?= -I$(PKG_INSTALL_PATH)/include
PKG_CXXFLAGS ?= -I$(PKG_INSTALL_PATH)/include

# We want relocatable execution, eg for container chroot add-ons
# Can split for build/device if needed
PKG_RPATH_REL := $$ORIGIN/../lib:$$ORIGIN/../lib/$(PKG_HOST_GNU_TYPE)
PKG_LDFLAGS  := -L$(PKG_INSTALL_PATH)/lib -L$(PKG_INSTALL_PATH)/lib/$(PKG_HOST_GNU_TYPE) \
	-Wl,-rpath,$(PKG_RPATH_REL) \
	-Wl,-rpath-link,$(PKG_INSTALL_PATH)/lib \
	-Wl,-rpath-link,$(PKG_INSTALL_PATH)/lib/$(PKG_HOST_GNU_TYPE)

PKG_ARCHIVE_PATH := $(PKG_WORK_DIR)/$(PKG_ARCHIVE)
PKG_SOURCE_ROOT := $(PKG_WORK_DIR)/$(PKG_SOURCE_DIR)
PKG_SOURCE_PATH := $(PKG_SOURCE_ROOT)/$(PKG_SUBDIR)
PKG_BUILD_PATH := $(PKG_SOURCE_ROOT)-build
PKG_BUILD_LOG := $(PKG_WORK_DIR)/$(PKG_NAME)-$(PKG_VER).log


.DEFAULT_GOAL := $(PKG_INSTALL_STAMP)


# Command runner with logging
define run
	printf 'target:%s\n' "$@" >> $(PKG_BUILD_LOG)
	printf 'run:%s\n' "$(1)" >> $(PKG_BUILD_LOG)
	if $(1) >> $(PKG_BUILD_LOG) 2>&1 ; then \
		true; \
	else \
		_err=$$?; \
		cat "$(PKG_BUILD_LOG)"; \
		exit $$_err; \
	fi
endef


# Get source, unpack, patch
$(PKG_WORK_DIR) $(PKG_BUILD_PATH) $(PKG_DESTDIR) $(PKG_RUNTIME_DESTDIR):
	@mkdir -p $@

$(PKG_BUILD_LOG):
	@mkdir -p $(@D)
	@: > $@

$(PKG_ARCHIVE_PATH): | $(PKG_META_PATH) $(PKG_WORK_DIR) $(PKG_BUILD_LOG)
	@$(call run,vfetch $(PKG_META_PATH) $@)

$(PKG_SOURCE_ROOT): $(PKG_ARCHIVE_PATH) $(PKG_PATCHES)
	@test -d $@ && rm -rf $@ ; true
	@mkdir -p $@
	@tar -xpf $< --strip-components $(PKG_UNPACK_STRIP) -C $@

ifeq ($(strip $(PKG_PATCHES)),)
$(PKG_PATCH_STAMP): | $(PKG_SOURCE_ROOT)
	@touch $@
else
$(PKG_PATCH_STAMP): $(PKG_PATCHES) | $(PKG_SOURCE_ROOT)
	@$(call run,for patch in $(PKG_PATCHES); do echo $$patch && \
		patch -d $(firstword $|) -p$(PKG_PATCH_STRIP) < "$$patch"; done)
	@touch $@
endif

$(PKG_SOURCE_STAMP): $(PKG_PATCH_STAMP)
	@touch $@


source: $(PKG_SOURCE_STAMP)


# Build and Install

ifeq ($(PKG_BUILD_SCHEME),pysrc)

# https://github.com/pypa/pip/issues/10978
define installwheel
	$(call run,env $(PKG_ENVIRONMENT) \
		python3 -m pip install \
			--find-links $(PIP_WHEELS) \
			--root=$(1) \
			--prefix="$(PKG_PREFIX)" \
			--ignore-installed \
			$(2) \
			$(PKG_NAME)==$(PKG_VER))
endef

PIP_CACHE  := $(PKG_CACHE_ROOT)/pip-cache
PIP_WHEELS := $(PKG_CACHE_ROOT)/pip-wheels

PKG_ENVIRONMENT += PIP_CACHE_DIR=$(PIP_CACHE)
PKG_ENVIRONMENT += PIP_PREFER_BINARY=1

$(PKG_CACHE_ROOT) $(PIP_WHEELS):
	@mkdir -p $@

$(PKG_BUILD_STAMP): $(PKG_SOURCE_STAMP) | $(PKG_CACHE) $(PIP_WHEELS)
	@$(call run,env $(PKG_ENVIRONMENT) \
		python3 -m pip wheel --wheel-dir $(PIP_WHEELS) $(PKG_SOURCE_PATH))
	@touch $@

$(PKG_INSTALL_STAMP): $(PKG_BUILD_STAMP) | $(PKG_DESTDIR) $(PKG_RUNTIME_DESTDIR)
	@$(foreach d,$|,$(call installwheel,$(d));)
	@rm -rf \
		$(PKG_RUNTIME_PATH)/lib/python*/dist-packages/*.dist-info \
		$(PKG_RUNTIME_PATH)/lib/python*/dist-packages/*.data \
		$(PKG_RUNTIME_PATH)/lib/python*/dist-packages/test* \
		$(PKG_RUNTIME_PATH)/lib/python*/dist-packages/__pycache__ \
		$(PKG_RUNTIME_PATH)/share/doc \
		$(PKG_RUNTIME_PATH)/share/man
	@touch $@

else ifeq ($(PKG_BUILD_SCHEME),autotools)

PKG_ENVIRONMENT += PKG_CONFIG_SYSROOT_DIR=$(PKG_DESTDIR)
PKG_ENVIRONMENT += PKG_CONFIG_PATH=$(PKG_INSTALL_PATH)/lib/pkgconfig:$(PKG_INSTALL_PATH)/share/pkgconfig
PKG_ENVIRONMENT += PKG_CONFIG_LIBDIR=$(PKG_INSTALL_PATH)/lib/pkgconfig:$(PKG_INSTALL_PATH)/lib/$(PKG_HOST_GNU_TYPE)/pkgconfig
PKG_ENVIRONMENT += PKG_CONFIG=pkg-config
PKG_ENVIRONMENT += CPPFLAGS="$(PKG_CPPFLAGS)"
PKG_ENVIRONMENT += CFLAGS="$(PKG_CFLAGS)"
PKG_ENVIRONMENT += CXXFLAGS="$(PKG_CXXFLAGS)"
PKG_ENVIRONMENT += LDFLAGS="$(PKG_LDFLAGS)"
PKG_ENVIRONMENT += MAKEINFO=true

$(PKG_SOURCE_PATH)/configure: $(PKG_SOURCE_STAMP)
	@$(call run,(cd $(@D) && \
		if test -f ./configure; then \
			:; \
		elif test -x ./autogen.sh; then \
			NOCONFIGURE=1 ./autogen.sh; \
		else \
			autoreconf -fi; \
		fi))
	@test -s $@

$(PKG_BUILD_PATH)/Makefile: $(PKG_SOURCE_PATH)/configure | $(PKG_BUILD_PATH) $(PKG_DESTDIR)
	@$(call run,(cd $(PKG_BUILD_PATH) && \
		env $(PKG_ENVIRONMENT) \
		$(PKG_SOURCE_PATH)/configure \
		--build=$(PKG_BUILD_GNU_TYPE) \
		--host=$(PKG_HOST_GNU_TYPE) \
		--with-sysroot=$(PKG_DESTDIR) \
		--prefix=$(PKG_PREFIX) \
		--sysconfdir=/etc \
		$(PKG_CONFIGURE_OPTS)))
	@test -s $@

$(PKG_BUILD_STAMP): $(PKG_BUILD_PATH)/Makefile
	@$(call run,env $(PKG_ENVIRONMENT) \
		$(MAKE) -C $(PKG_BUILD_PATH))
	@touch $@

$(PKG_INSTALL_STAMP): $(PKG_BUILD_STAMP) | $(PKG_RUNTIME_DESTDIR) $(PKG_DESTDIR)
	@$(foreach d,$|,$(call run,env $(PKG_ENVIRONMENT) \
		$(MAKE) -C $(PKG_BUILD_PATH) install DESTDIR=$(d));)
	@rm -rf \
		$(PKG_RUNTIME_PATH)/lib/*.a \
		$(PKG_RUNTIME_PATH)/lib/*.la \
		$(PKG_RUNTIME_PATH)/include \
		$(PKG_RUNTIME_PATH)/lib/pkgconfig \
		$(PKG_RUNTIME_PATH)/share/doc \
		$(PKG_RUNTIME_PATH)/share/man
	@touch $@
else
$(error Unknown build scheme)
endif

.PHONY: install
install: $(PKG_INSTALL_STAMP)
