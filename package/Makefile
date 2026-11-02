$(if $(IGconf_sys_buildroot),, $(error IGconf_sys_buildroot is not defined))

PKG_ROOT := $(abspath $(CURDIR))
PKG_ENV  := $(abspath $(PKG_ROOT)/shared/pkg-env.mk)
DEPGEN   := $(abspath $(PKG_ROOT)/shared/depgen.py)

ifeq ($(strip $(MAKECMDGOALS)),)
  $(error No packages specified)
endif

# Package name is its path under package/, eg thispkg or foo/thatpkg
pkgs_in = $(foreach p,$(1),$(if $(wildcard $(PKG_ROOT)/$(p)/Makefile),$(p)))

REQUESTED_PKGS := $(call pkgs_in,$(MAKECMDGOALS))
CLEAN_PKGS := $(call pkgs_in,$(patsubst clean-%,%,$(filter clean-%,$(MAKECMDGOALS))))
PACKAGE_GOALS := $(sort $(REQUESTED_PKGS))

DEP_DIR  := $(IGconf_sys_buildroot)/pkgdeps
DEPFILES := $(PACKAGE_GOALS:%=$(DEP_DIR)/%.deps.mk)

ALL_PACKAGE_STAMPS :=
ALL_PACKAGE_DIRS :=

.PHONY: all clean finalise $(REQUESTED_PKGS)

-include $(DEPFILES)

all: $(ALL_PACKAGE_STAMPS)

# Packages share the runtime tree. Only prune it once they've all installed
finalise: $(ALL_PACKAGE_STAMPS)
	@$(foreach d,$(ALL_PACKAGE_DIRS),$(MAKE) -C "$(d)" --no-print-directory prune &&) true

$(PACKAGE_GOALS): finalise

$(DEP_DIR)/%.deps.mk: $(PKG_ROOT)/%/Makefile $(PKG_ENV) $(DEPGEN)
	@mkdir -p "$(@D)"
	@$(MAKE) -C "$(PKG_ROOT)/$*" --no-print-directory deps-mk \
		IGconf_sys_buildroot="$(IGconf_sys_buildroot)" \
		DEP_OUT="$@" \
		DEPGEN="$(DEPGEN)"

$(CLEAN_PKGS:%=clean-%): clean-%:
	@rm -f "$(DEP_DIR)/$*.deps.mk"
	@rm -rf "$(IGconf_sys_buildroot)/$*"
