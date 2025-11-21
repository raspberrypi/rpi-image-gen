$(if $(IGconf_sys_buildroot),, $(error IGconf_sys_buildroot is not defined))

PKG_ROOT := $(abspath $(CURDIR))
PKG_ENV  := $(abspath $(PKG_ROOT)/shared/pkg-env.mk)
DEPGEN   := $(abspath $(PKG_ROOT)/shared/depgen.py)

PACKAGE_MAKEFILES := $(wildcard $(PKG_ROOT)/*/Makefile)
KNOWN_PKGS := $(sort $(patsubst $(PKG_ROOT)/%/Makefile,%,$(PACKAGE_MAKEFILES)))

ifeq ($(strip $(MAKECMDGOALS)),)
  $(error No packages specified)
endif

REQUESTED_PKGS := $(filter $(KNOWN_PKGS),$(MAKECMDGOALS))
PACKAGE_GOALS := $(sort $(REQUESTED_PKGS))

DEP_DIR  := $(IGconf_sys_buildroot)/pkgdeps
DEPFILES := $(PACKAGE_GOALS:%=$(DEP_DIR)/%.deps.mk)

ALL_PACKAGE_STAMPS :=

.PHONY: all clean $(KNOWN_PKGS)

-include $(DEPFILES)

all: $(ALL_PACKAGE_STAMPS)

$(DEP_DIR)/%.deps.mk: $(PKG_ROOT)/%/Makefile $(PKG_ENV) $(DEPGEN)
	@mkdir -p "$(DEP_DIR)"
	@python3 "$(DEPGEN)" \
		--package "$*" \
		--makefile "$<" \
		--pkg-dir "$(PKG_ROOT)/$*" \
		--pkg-env "$(PKG_ENV)" \
		--out "$@"

clean-%:
	@rm -f "$(DEP_DIR)/$*.deps.mk"
	@rm -rf "$(IGconf_sys_buildroot)/$*"
