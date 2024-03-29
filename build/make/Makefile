##
##  Copyright (c) 2010 The WebM project authors. All Rights Reserved.
##
##  Use of this source code is governed by a BSD-style license
##  that can be found in the LICENSE file in the root of the source
##  tree. An additional intellectual property rights grant can be found
##  in the file PATENTS.  All contributing project authors may
##  be found in the AUTHORS file in the root of the source tree.
##


include config.mk
quiet?=true
ifeq ($(target),)
# If a target wasn't specified, invoke for all enabled targets.
.DEFAULT:
	@for t in $(ALL_TARGETS); do \
	     $(MAKE) --no-print-directory target=$$t $(MAKECMDGOALS) || exit $$?;\
        done
all: .DEFAULT
clean:: .DEFAULT
install:: .DEFAULT


# Note: md5sum is not installed on OS X, but openssl is. Openssl may not be
# installed on cygwin, so we need to autodetect here.
md5sum := $(firstword $(wildcard \
          $(foreach e,md5sum openssl,\
          $(foreach p,$(subst :, ,$(PATH)),$(p)/$(e)*))\
          ))
md5sum := $(if $(filter %openssl,$(md5sum)),$(md5sum) dgst -md5,$(md5sum))

TGT_CC:=$(word 3, $(subst -, ,$(TOOLCHAIN)))
dist:
	@for t in $(ALL_TARGETS); do \
	     $(MAKE) --no-print-directory target=$$t $(MAKECMDGOALS) || exit $$?;\
        done
        # Run configure for the user with the current toolchain.
	@if [ -d "$(DIST_DIR)/src" ]; then \
            mkdir -p "$(DIST_DIR)/build"; \
            cd "$(DIST_DIR)/build"; \
            echo "Rerunning configure $(CONFIGURE_ARGS)"; \
            ../src/configure $(CONFIGURE_ARGS); \
            $(if $(filter vs%,$(TGT_CC)),make NO_LAUNCH_DEVENV=1;) \
        fi
	@if [ -d "$(DIST_DIR)" ]; then \
            echo "    [MD5SUM] $(DIST_DIR)"; \
	    cd $(DIST_DIR) && \
	    $(md5sum) `find . -name md5sums.txt -prune -o -type f -print` \
                | sed -e 's/MD5(\(.*\))= \([0-9a-f]\{32\}\)/\2  \1/' \
                > md5sums.txt;\
        fi


endif

ifneq ($(target),)
# Normally, we want to build the filename from the target and the toolchain.
# This disambiguates from the $(target).mk file that exists in the source tree.
# However, the toolchain is part of the target in universal builds, so we
# don't want to include TOOLCHAIN in that case. FAT_ARCHS is used to test
# if we're in the universal case.
include $(target)$(if $(FAT_ARCHS),,-$(TOOLCHAIN)).mk
endif
BUILD_ROOT?=.
VPATH=$(SRC_PATH_BARE)
CFLAGS+=-I$(BUILD_PFX)$(BUILD_ROOT) -I$(SRC_PATH)
ASFLAGS+=-I$(BUILD_PFX)$(BUILD_ROOT)/ -I$(SRC_PATH)/
DIST_DIR?=dist
HOSTCC?=gcc
TGT_ISA:=$(word 1, $(subst -, ,$(TOOLCHAIN)))
TGT_OS:=$(word 2, $(subst -, ,$(TOOLCHAIN)))
TGT_CC:=$(word 3, $(subst -, ,$(TOOLCHAIN)))
quiet:=$(if $(verbose),,yes)
qexec=$(if $(quiet),@)

# Cancel built-in implicit rules
%: %.o
%.asm:
%.a:

#
# Common rules"
#
.PHONY: all-$(target)
all-$(target):

.PHONY: clean
clean::
	rm -f $(OBJS-yes) $(OBJS-yes:.o=.d) $(OBJS-yes:.asm.s.o=.asm.s)
	rm -f $(CLEAN-OBJS)

.PHONY: dist
dist:
.PHONY: install
install::

$(BUILD_PFX)%.c.d: %.c
	$(if $(quiet),@echo "    [DEP] $@")
	$(qexec)mkdir -p $(dir $@)
	$(qexec)$(CC) $(INTERNAL_CFLAGS) $(CFLAGS) -M $< | $(fmt_deps) > $@

$(BUILD_PFX)%.c.o: %.c
	$(if $(quiet),@echo "    [CC] $@")
	$(qexec)$(CC) $(INTERNAL_CFLAGS) $(CFLAGS) -c -o $@ $<

$(BUILD_PFX)%.asm.d: %.asm
	$(if $(quiet),@echo "    [DEP] $@")
	$(qexec)mkdir -p $(dir $@)
	$(qexec)$(SRC_PATH_BARE)/build/make/gen_asm_deps.sh \
            --build-pfx=$(BUILD_PFX) --depfile=$@ $(ASFLAGS) $< > $@

$(BUILD_PFX)%.asm.o: %.asm
	$(if $(quiet),@echo "    [AS] $@")
	$(qexec)$(AS) $(ASFLAGS) -o $@ $<

$(BUILD_PFX)%.s.d: %.s
	$(if $(quiet),@echo "    [DEP] $@")
	$(qexec)mkdir -p $(dir $@)
	$(qexec)$(SRC_PATH_BARE)/build/make/gen_asm_deps.sh \
            --build-pfx=$(BUILD_PFX) --depfile=$@ $(ASFLAGS) $< > $@

$(BUILD_PFX)%.s.o: %.s
	$(if $(quiet),@echo "    [AS] $@")
	$(qexec)$(AS) $(ASFLAGS) -o $@ $<

.PRECIOUS: %.c.S
%.c.S: CFLAGS += -DINLINE_ASM
$(BUILD_PFX)%.c.S: %.c
	$(if $(quiet),@echo "    [GEN] $@")
	$(qexec)$(CC) -S $(CFLAGS) -o $@ $<

.PRECIOUS: %.asm.s
$(BUILD_PFX)%.asm.s: %.asm
	$(if $(quiet),@echo "    [ASM CONVERSION] $@")
	$(qexec)mkdir -p $(dir $@)
	$(qexec)$(ASM_CONVERSION) <$< >$@

# If we're in debug mode, pretend we don't have GNU strip, to fall back to
# the copy implementation
HAVE_GNU_STRIP := $(if $(CONFIG_DEBUG),,$(HAVE_GNU_STRIP))
ifeq ($(HAVE_GNU_STRIP),yes)
# Older binutils strip global sybols not needed for relocation processing
# when given --strip-unneeded. Use nm and awk to identify globals and
# keep them.
%.a: %_g.a
	$(if $(quiet),@echo "    [STRIP] $@ < $<")
	$(qexec)$(STRIP) --strip-unneeded \
         `$(NM) $< | grep ' [A-TV-Z] ' | awk '{print "-K"$$3'}`\
          -o $@ $<
else
%.a: %_g.a
	$(if $(quiet),@echo "    [CP] $@ < $<")
	$(qexec)cp $< $@
endif

#
# Rule to extract assembly constants from C sources
#
obj_int_extract: build/make/obj_int_extract.c
	$(if $(quiet),@echo "    [HOSTCC] $@")
	$(qexec)$(HOSTCC) -I. -I$(SRC_PATH_BARE) -o $@ $<
CLEAN-OBJS += obj_int_extract

#
# Utility functions
#
pairmap=$(if $(strip $(2)),\
    $(call $(1),$(word 1,$(2)),$(word 2,$(2)))\
    $(call pairmap,$(1),$(wordlist 3,$(words $(2)),$(2)))\
)

enabled=$(filter-out $($(1)-no),$($(1)-yes))
cond_enabled=$(if $(filter yes,$($(1))), $(call enabled,$(2)))

find_file1=$(word 1,$(wildcard $(subst //,/,$(addsuffix /$(1),$(2)))))
find_file=$(foreach f,$(1),$(call find_file1,$(strip $(f)),$(strip $(2))) )
obj_pats=.c=.c.o $(AS_SFX)=$(AS_SFX).o
objs=$(addprefix $(BUILD_PFX),$(foreach p,$(obj_pats),$(filter %.o,$(1:$(p))) ))

install_map_templates=$(eval $(call install_map_template,$(1),$(2)))

not=$(subst yes,no,$(1))

ifeq ($(CONFIG_MSVS),yes)
lib_file_name=$(1).lib
else
lib_file_name=lib$(1).a
endif
#
# Rule Templates
#
define linker_template
$(1): $(filter-out -%,$(2))
$(1):
	$(if $(quiet),@echo    "    [LD] $$@")
	$(qexec)$$(LD) $$(strip $$(INTERNAL_LDFLAGS) $$(LDFLAGS) -o $$@ $(2) $(3) $$(extralibs))
endef
# make-3.80 has a bug with expanding large input strings to the eval function,
# which was triggered in some cases by the following component of
# linker_template:
#   $(1): $$(call find_file, $(patsubst -l%,lib%.a,$(filter -l%,$(2))),\
#                           $$(patsubst -L%,%,$$(filter -L%,$$(LDFLAGS) $(2))))
# This may be useful to revisit in the future (it tries to locate libraries
# in a search path and add them as prerequisites

define install_map_template
$(DIST_DIR)/$(1): $(2)
	$(if $(quiet),@echo "    [INSTALL] $$@")
	$(qexec)mkdir -p $$(dir $$@)
	$(qexec)cp -p $$< $$@
endef

define archive_template
# Not using a pattern rule here because we don't want to generate empty
# archives when they are listed as a dependency in files not responsible
# for creating them.
$(1):
	$(if $(quiet),@echo "    [AR] $$@")
	$(qexec)$$(AR) $$(ARFLAGS) $$@ $$?
endef

define so_template
# Not using a pattern rule here because we don't want to generate empty
# archives when they are listed as a dependency in files not responsible
# for creating them.
#
# This needs further abstraction for dealing with non-GNU linkers.
$(1):
	$(if $(quiet),@echo "    [LD] $$@")
	$(qexec)$$(LD) -shared $$(LDFLAGS) \
            -Wl,--no-undefined -Wl,-soname,$$(SONAME) \
            -Wl,--version-script,$$(SO_VERSION_SCRIPT) -o $$@ \
            $$(filter %.o,$$?) $$(extralibs)
endef

define lipo_lib_template
$(1): $(addsuffix /$(1),$(FAT_ARCHS))
	$(if $(quiet),@echo "    [LIPO] $$@")
	$(qexec)libtool -static -o $$@ $$?
endef

define lipo_bin_template
$(1): $(addsuffix /$(1),$(FAT_ARCHS))
	$(if $(quiet),@echo "    [LIPO] $$@")
	$(qexec)lipo -output $$@ -create $$?
endef


#
# Get current configuration
#
ifneq ($(target),)
include $(SRC_PATH_BARE)/$(target:-$(TOOLCHAIN)=).mk
endif
ifeq ($(filter clean,$(MAKECMDGOALS)),)
  # Older versions of make don't like -include directives with no arguments
  ifneq ($(filter %.d,$(OBJS-yes:.o=.d)),)
    -include $(filter %.d,$(OBJS-yes:.o=.d))
  endif
endif

#
# Configuration dependent rules
#
$(call pairmap,install_map_templates,$(INSTALL_MAPS))

DOCS=$(call cond_enabled,CONFIG_INSTALL_DOCS,DOCS)
.docs: $(DOCS)
	@touch $@

INSTALL-DOCS=$(call cond_enabled,CONFIG_INSTALL_DOCS,INSTALL-DOCS)
ifeq ($(MAKECMDGOALS),dist)
INSTALL-DOCS+=$(call cond_enabled,CONFIG_INSTALL_DOCS,DIST-DOCS)
endif
.install-docs: .docs $(addprefix $(DIST_DIR)/,$(INSTALL-DOCS))
	@touch $@

clean::
	rm -f .docs .install-docs $(DOCS)

BINS=$(call enabled,BINS)
.bins: $(BINS)
	@touch $@

INSTALL-BINS=$(call cond_enabled,CONFIG_INSTALL_BINS,INSTALL-BINS)
ifeq ($(MAKECMDGOALS),dist)
INSTALL-BINS+=$(call cond_enabled,CONFIG_INSTALL_BINS,DIST-BINS)
endif
.install-bins: .bins $(addprefix $(DIST_DIR)/,$(INSTALL-BINS))
	@touch $@

clean::
	rm -f .bins .install-bins $(BINS)

LIBS=$(call enabled,LIBS)
.libs: $(LIBS)
	@touch $@
$(foreach lib,$(filter %_g.a,$(LIBS)),$(eval $(call archive_template,$(lib))))
$(foreach lib,$(filter %so.$(VERSION_MAJOR).$(VERSION_MINOR).$(VERSION_PATCH),$(LIBS)),$(eval $(call so_template,$(lib))))

INSTALL-LIBS=$(call cond_enabled,CONFIG_INSTALL_LIBS,INSTALL-LIBS)
ifeq ($(MAKECMDGOALS),dist)
INSTALL-LIBS+=$(call cond_enabled,CONFIG_INSTALL_LIBS,DIST-LIBS)
endif
.install-libs: .libs $(addprefix $(DIST_DIR)/,$(INSTALL-LIBS))
	@touch $@

clean::
	rm -f .libs .install-libs $(LIBS)

ifeq ($(CONFIG_EXTERNAL_BUILD),yes)
PROJECTS=$(call enabled,PROJECTS)
.projects: $(PROJECTS)
	@touch $@

INSTALL-PROJECTS=$(call cond_enabled,CONFIG_INSTALL_PROJECTS,INSTALL-PROJECTS)
ifeq ($(MAKECMDGOALS),dist)
INSTALL-PROJECTS+=$(call cond_enabled,CONFIG_INSTALL_PROJECTS,DIST-PROJECTS)
endif
.install-projects: .projects $(addprefix $(DIST_DIR)/,$(INSTALL-PROJECTS))
	@touch $@

clean::
	rm -f .projects .install-projects $(PROJECTS)
endif

# If there are any source files to be distributed, then include the build
# system too.
ifneq ($(call enabled,DIST-SRCS),)
    DIST-SRCS-yes            += configure
    DIST-SRCS-yes            += build/make/configure.sh
    DIST-SRCS-yes            += build/make/gen_asm_deps.sh
    DIST-SRCS-yes            += build/make/Makefile
    DIST-SRCS-$(CONFIG_MSVS)  += build/make/gen_msvs_def.sh
    DIST-SRCS-$(CONFIG_MSVS)  += build/make/gen_msvs_proj.sh
    DIST-SRCS-$(CONFIG_MSVS)  += build/make/gen_msvs_sln.sh
    DIST-SRCS-$(CONFIG_MSVS)  += build/x86-msvs/yasm.rules
    DIST-SRCS-$(CONFIG_MSVS)  += build/x86-msvs/obj_int_extract.bat
    DIST-SRCS-$(CONFIG_RVCT) += build/make/armlink_adapter.sh
    # Include obj_int_extract if we use offsets from asm_*_offsets
    DIST-SRCS-$(ARCH_ARM)$(ARCH_X86)$(ARCH_X86_64)    += build/make/obj_int_extract.c
    DIST-SRCS-$(ARCH_ARM)    += build/make/ads2gas.pl
    DIST-SRCS-yes            += $(target:-$(TOOLCHAIN)=).mk
endif
INSTALL-SRCS := $(call cond_enabled,CONFIG_INSTALL_SRCS,INSTALL-SRCS)
ifeq ($(MAKECMDGOALS),dist)
INSTALL-SRCS += $(call cond_enabled,CONFIG_INSTALL_SRCS,DIST-SRCS)
endif
.install-srcs: $(addprefix $(DIST_DIR)/src/,$(INSTALL-SRCS))
	@touch $@

clean::
	rm -f .install-srcs

ifeq ($(CONFIG_EXTERNAL_BUILD),yes)
    BUILD_TARGETS += .projects
    INSTALL_TARGETS += .install-projects
endif
BUILD_TARGETS += .docs .libs .bins
INSTALL_TARGETS += .install-docs .install-srcs .install-libs .install-bins
all-$(target): $(BUILD_TARGETS)
install:: $(INSTALL_TARGETS)
dist: $(INSTALL_TARGETS)
