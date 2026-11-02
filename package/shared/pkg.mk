PKG_SHARED_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
include $(PKG_SHARED_DIR)/pkg-env.mk

PKG_DESTDIR         ?= $(abspath $(IGconf_sys_buildroot)/staging/$(PKG_HOST_GNU_TYPE))
PKG_RUNTIME_DESTDIR ?= $(abspath $(IGconf_sys_buildroot)/host/$(PKG_HOST_GNU_TYPE))
PKG_PREFIX          ?= /usr
PKG_CACHE_ROOT      := $(abspath $(if $(strip $(IGconf_sys_cachedir)),$(IGconf_sys_cachedir),/tmp))

$(if $(strip $(PKG_DESTDIR)),,$(error PKG_DESTDIR must not be empty))
$(if $(strip $(PKG_RUNTIME_DESTDIR)),,$(error PKG_RUNTIME_DESTDIR must not be empty))

PKG_INSTALL_PATH := $(abspath $(PKG_DESTDIR)/$(PKG_PREFIX))
PKG_RUNTIME_PATH := $(abspath $(PKG_RUNTIME_DESTDIR)/$(PKG_PREFIX))

THIS_PKG ?= $(CURDIR)

PKG_META ?= $(PKG_STEM)-$(PKG_VER).meta
PKG_META_PATH := $(abspath $(THIS_PKG)/$(PKG_META))
ifeq (,$(wildcard $(PKG_META_PATH)))
$(error $(PKG_META_PATH) not found)
endif
PKG_SOURCE_DIR ?= $(PKG_STEM)-$(PKG_VER)
PKG_ARCHIVE ?= $(PKG_STEM)-$(PKG_VER).tar.gz
PKG_SUBDIR ?= .

PKG_ENVIRONMENT    ?=
PKG_BUILD_SCHEME   ?=
PKG_PATCH_DIR      ?= patches/$(PKG_VER)
PKG_PATCHES        := $(sort $(wildcard $(abspath $(THIS_PKG)/$(PKG_PATCH_DIR))/*.patch))
PKG_PATCH_STRIP    ?= 1
PKG_UNPACK_STRIP   ?= 1
PKG_CONFIGURE_OPTS ?=
PKG_LIB_SHARED     ?= lib$(patsubst lib%,%,$(PKG_STEM))*.so*
PKG_MAKE_OPTS      ?=

# Set to y for offline builds - no network access during package build
IG_OFFLINE ?= n

PKG_USE_HOST_PKGCONFIG ?= 0
ifeq ($(PKG_USE_HOST_PKGCONFIG),1)
ifneq ($(PKG_BUILD_GNU_TYPE),$(PKG_HOST_GNU_TYPE))
$(error PKG_USE_HOST_PKGCONFIG=1 not permitted for cross-build)
endif
endif

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
PKG_BUILD_LOG := $(PKG_WORK_DIR)/$(PKG_STEM)-$(PKG_VER).log


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


define msg
	@printf '  %-14s %s %s\n' "$(1)" "$(PKG_NAME)" "$(PKG_VER)"
endef


# Get source, unpack, patch
$(PKG_WORK_DIR) $(PKG_BUILD_PATH) $(PKG_DESTDIR) $(PKG_RUNTIME_DESTDIR):
	@mkdir -p $@

$(PKG_BUILD_LOG):
	@mkdir -p $(@D)
	@: > $@

$(PKG_ARCHIVE_PATH): $(PKG_META_PATH) | $(PKG_WORK_DIR) $(PKG_BUILD_LOG)
	$(call msg,GET)
	@$(call run,vfetch $(PKG_META_PATH) $@ $(IG_OFFLINE))

$(PKG_SOURCE_ROOT): $(PKG_ARCHIVE_PATH) $(PKG_PATCHES)
	$(call msg,UNPACK)
	@test -d $@ && rm -rf $@ ; true
	@mkdir -p $@
	@tar -xpf $< --strip-components $(PKG_UNPACK_STRIP) -C $@

ifeq ($(strip $(PKG_PATCHES)),)
$(PKG_PATCH_STAMP): | $(PKG_SOURCE_ROOT)
	@touch $@
else
$(PKG_PATCH_STAMP): $(PKG_PATCHES) | $(PKG_SOURCE_ROOT)
	$(call msg,PATCH)
	@$(call run,for patch in $(PKG_PATCHES); do echo $$patch && \
		patch -d $(firstword $|) -p$(PKG_PATCH_STRIP) < "$$patch"; done)
	@touch $@
endif

$(PKG_SOURCE_STAMP): $(PKG_PATCH_STAMP)
	@touch $@


source: $(PKG_SOURCE_STAMP)


# Build and Install

# Environment for the schemes which configure a toolchain
ifneq ($(filter autotools cmake,$(PKG_BUILD_SCHEME)),)
ifeq ($(PKG_USE_HOST_PKGCONFIG),1)
PKG_ENVIRONMENT += PKG_CONFIG_SYSROOT_DIR=
PKG_ENVIRONMENT += PKG_CONFIG_PATH=/usr/lib/$(PKG_HOST_GNU_TYPE)/pkgconfig:/usr/lib/pkgconfig:/usr/share/pkgconfig
PKG_ENVIRONMENT += PKG_CONFIG_LIBDIR=/usr/lib/$(PKG_HOST_GNU_TYPE)/pkgconfig:/usr/lib/pkgconfig:/usr/share/pkgconfig
else
PKG_ENVIRONMENT += PKG_CONFIG_SYSROOT_DIR=$(PKG_DESTDIR)
PKG_ENVIRONMENT += PKG_CONFIG_PATH=$(PKG_INSTALL_PATH)/lib/pkgconfig:$(PKG_INSTALL_PATH)/share/pkgconfig
PKG_ENVIRONMENT += PKG_CONFIG_LIBDIR=$(PKG_INSTALL_PATH)/lib/pkgconfig:$(PKG_INSTALL_PATH)/lib/$(PKG_HOST_GNU_TYPE)/pkgconfig
endif

PKG_ENVIRONMENT += PKG_CONFIG=pkg-config
PKG_ENVIRONMENT += CPPFLAGS="$(PKG_CPPFLAGS)"
PKG_ENVIRONMENT += CFLAGS="$(PKG_CFLAGS)"
PKG_ENVIRONMENT += CXXFLAGS="$(PKG_CXXFLAGS)"
# Pass $ORIGIN in rpath literally
PKG_ENVIRONMENT += LDFLAGS='$(PKG_LDFLAGS_ENV)'
PKG_ENVIRONMENT += MAKEINFO=true
endif

# Defines what's removed from the runtime tree
PKG_RUNTIME_PRUNE += \
	share/doc \
	share/man

ifeq ($(PKG_BUILD_SCHEME),pysrc)

PKG_RUNTIME_PRUNE += \
	lib/python*/dist-packages/*.dist-info \
	lib/python*/dist-packages/*.data \
	lib/python*/dist-packages/test* \
	lib/python*/dist-packages/__pycache__

# https://github.com/pypa/pip/issues/10978
define installwheel
	$(call run,env $(PKG_ENVIRONMENT) \
		python3 -m pip install \
			$(PIP_ARGS) \
			--find-links $(PIP_WHEELS) \
			--root=$(1) \
			--prefix="$(PKG_PREFIX)" \
			--ignore-installed \
			$(2) \
			$(PKG_STEM)==$(PKG_VER))
endef

PIP_CACHE  := $(PKG_CACHE_ROOT)/pip-cache
PIP_WHEELS := $(PKG_CACHE_ROOT)/pip-wheels

PKG_ENVIRONMENT += PIP_CACHE_DIR=$(PIP_CACHE)
PKG_ENVIRONMENT += PIP_PREFER_BINARY=1

ifeq ($(IG_OFFLINE),y)
PIP_ARGS += --no-index --find-links $(PIP_WHEELS) --no-build-isolation
PKG_ENVIRONMENT += PIP_NO_INDEX=1
PKG_ENVIRONMENT += PIP_FIND_LINKS=$(PIP_WHEELS)
endif

$(PKG_CACHE_ROOT) $(PIP_CACHE) $(PIP_WHEELS):
	@mkdir -p $@

$(PKG_BUILD_STAMP): $(PKG_SOURCE_STAMP) | $(PIP_CACHE) $(PIP_WHEELS)
	$(call msg,BUILD)
	@$(call run,env $(PKG_ENVIRONMENT) \
		python3 -m pip wheel $(PIP_ARGS) --wheel-dir $(PIP_WHEELS) $(PKG_SOURCE_PATH))
	@touch $@

$(PKG_INSTALL_STAMP): $(PKG_BUILD_STAMP) | $(PKG_DESTDIR) $(PKG_RUNTIME_DESTDIR)
	$(call msg,INSTALL)
	@$(foreach d,$|,$(call installwheel,$(d));)
	@touch $@

else ifeq ($(PKG_BUILD_SCHEME),autotools)

PKG_RUNTIME_PRUNE += \
	lib/*.a \
	lib/*.la \
	include \
	lib/pkgconfig

# configure copies LDFLAGS into the generated Makefile, so escape $ORIGIN for make
PKG_LDFLAGS_ENV = $(subst $$ORIGIN,\$$$$ORIGIN,$(PKG_LDFLAGS))

$(PKG_SOURCE_PATH)/configure: $(PKG_SOURCE_STAMP)
	$(call msg,AUTORECONF)
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
	$(call msg,CONFIGURE)
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
	$(call msg,BUILD)
	@$(call run,env $(PKG_ENVIRONMENT) \
		$(MAKE) -C $(PKG_BUILD_PATH) $(PKG_MAKE_OPTS))
	@touch $@

$(PKG_INSTALL_STAMP): $(PKG_BUILD_STAMP) | $(PKG_RUNTIME_DESTDIR) $(PKG_DESTDIR)
	$(call msg,INSTALL)
	@$(foreach d,$|,$(call run,env $(PKG_ENVIRONMENT) \
		$(MAKE) -C $(PKG_BUILD_PATH) install $(PKG_MAKE_OPTS) DESTDIR=$(d));)
	@touch $@

else ifeq ($(PKG_BUILD_SCHEME),cmake)

PKG_RUNTIME_PRUNE += \
	lib/*.a \
	lib/cmake \
	include \
	lib/pkgconfig

PKG_LDFLAGS_ENV = $(PKG_LDFLAGS)

PKG_CMAKE_BUILD_TYPE ?= Release

PKG_CMAKE_OPTS := \
	-DCMAKE_BUILD_TYPE=$(PKG_CMAKE_BUILD_TYPE) \
	-DCMAKE_INSTALL_PREFIX=$(PKG_PREFIX) \
	-DCMAKE_INSTALL_SYSCONFDIR=/etc \
	-DCMAKE_INSTALL_LIBDIR=lib \
	-DCMAKE_PREFIX_PATH=$(PKG_INSTALL_PATH)

ifneq ($(PKG_BUILD_GNU_TYPE),$(PKG_HOST_GNU_TYPE))
PKG_CMAKE_OPTS += \
	-DCMAKE_SYSTEM_NAME=Linux \
	-DCMAKE_SYSTEM_PROCESSOR=$(firstword $(subst -, ,$(PKG_HOST_GNU_TYPE))) \
	-DCMAKE_C_COMPILER=$(PKG_HOST_GNU_TYPE)-gcc \
	-DCMAKE_CXX_COMPILER=$(PKG_HOST_GNU_TYPE)-g++
endif

PKG_ENVIRONMENT += CMAKE_GENERATOR="Unix Makefiles"

$(PKG_SOURCE_PATH)/CMakeLists.txt: $(PKG_SOURCE_STAMP)
	@test -s $@

$(PKG_BUILD_PATH)/Makefile: $(PKG_SOURCE_PATH)/CMakeLists.txt | $(PKG_BUILD_PATH) $(PKG_DESTDIR)
	$(call msg,CONFIGURE)
	@$(call run,env $(PKG_ENVIRONMENT) \
		cmake --fresh -S $(PKG_SOURCE_PATH) -B $(PKG_BUILD_PATH) \
		$(PKG_CMAKE_OPTS) \
		$(PKG_CONFIGURE_OPTS))
	@test -s $@

$(PKG_BUILD_STAMP): $(PKG_BUILD_PATH)/Makefile
	$(call msg,BUILD)
	@$(call run,env $(PKG_ENVIRONMENT) \
		$(MAKE) -C $(PKG_BUILD_PATH) $(PKG_MAKE_OPTS))
	@touch $@

$(PKG_INSTALL_STAMP): $(PKG_BUILD_STAMP) | $(PKG_RUNTIME_DESTDIR) $(PKG_DESTDIR)
	$(call msg,INSTALL)
	@$(foreach d,$|,$(call run,env $(PKG_ENVIRONMENT) \
		$(MAKE) -C $(PKG_BUILD_PATH) install $(PKG_MAKE_OPTS) DESTDIR=$(d));)
	@touch $@

else ifeq ($(PKG_BUILD_SCHEME),makefile)

PKG_RUNTIME_PRUNE += \
	lib/*.a \
	lib/*.la \
	include \
	lib/pkgconfig

PKG_ENVIRONMENT += CC="$(PKG_HOST_GNU_TYPE)-gcc"

$(PKG_BUILD_STAMP): $(PKG_SOURCE_STAMP)
	$(call msg,BUILD)
	@$(call run,env $(PKG_ENVIRONMENT) \
		$(MAKE) -C $(PKG_SOURCE_PATH) $(PKG_MAKE_OPTS))
	@touch $@

$(PKG_INSTALL_STAMP): $(PKG_BUILD_STAMP) | $(PKG_DESTDIR) $(PKG_RUNTIME_DESTDIR)
	$(call msg,INSTALL)
	@$(foreach d,$|,$(call run,env $(PKG_ENVIRONMENT) \
		$(MAKE) -C $(PKG_SOURCE_PATH) install $(PKG_MAKE_OPTS) \
		PREFIX=$(PKG_PREFIX) DESTDIR=$(d));)
	@touch $@

else
$(error Unknown build scheme)
endif

.PHONY: install
install: $(PKG_INSTALL_STAMP)

.PHONY: prune
prune:
	@rm -rf $(addprefix $(PKG_RUNTIME_PATH)/,$(PKG_RUNTIME_PRUNE))

.PHONY: deps-mk
deps-mk:
	@python3 "$(DEPGEN)" \
		--name "$(PKG_NAME)" \
		--ver "$(PKG_VER)" \
		--deps "$(PKG_DEPS)" \
		--pkg-dir "$(THIS_PKG)" \
		--pkg-env "$(abspath $(PKG_SHARED_DIR)pkg-env.mk)" \
		--out "$(DEP_OUT)"
