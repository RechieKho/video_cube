# --- CUBE MAKEFILE ---
# Zero-configuration modular makefile.
# Library, binary & header files are exported to the root project.

CURRENT_DIR:=$(dir $(realpath $(firstword $(MAKEFILE_LIST))))

INCLUDE_DIR:=$(CURRENT_DIR)include/
SOURCE_DIR:=$(CURRENT_DIR)source/
SOURCE_BIN_DIR:=$(SOURCE_DIR)bin/
SOURCE_LIB_DIR:=$(SOURCE_DIR)lib/
GEN_DIR:=$(CURRENT_DIR)gen/
CUBE_DIR:=$(CURRENT_DIR)cube/
PLATFORM_DIR:=$(CURRENT_DIR)platform/
LINK_DIR:=$(PLATFORM_DIR)link/
TOOLCHAIN_DIR:=$(PLATFORM_DIR)toolchain/

# Detect host platform
# PLATFORM := windows || linux || macos
# ARCH := x86_32 || x86_64 || arm
ifeq ($(OS),Windows_NT)
	export PLATFORM?=windows
	ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)
		export ARCH?=x86_64
	else ifeq ($(PROCESSOR_ARCHITECTURE),x86)
		export ARCH?=x86_32
	else 
		$(info "Undefined arch '$(PROCESSOR_ARCHITECTURE)', default to 'x86_64'.")
		export ARCH?=x86_64
	endif
else
	UNAME_PLATFORM:= $(shell uname -s)
	ifeq ($(UNAME_PLATFORM),Linux)
		export PLATFORM?=linux
	else ifeq ($(UNAME_PLATFORM),Darwin)
		export PLATFORM?=macos
	else
		$(info "Undefined platform '$(UNAME_PLATFORM)', default to 'Linux'.")
		export PLATFORM?=linux
	endif

	UNAME_ARCH := $(shell uname -p)
	ifeq ($(UNAME_ARCH),x86_64)
		export ARCH?=x86_64
	else ifneq ($(filter %86,$(UNAME_ARCH)),)
		export ARCH?=x86_32
	else ifneq ($(filter arm%,$(UNAME_ARCH)),)
		export ARCH?=arm
	else
		$(info "Undefined arch '$(UNAME_ARCH)', default to 'x86_64'.")
		ARCH:=x86_64
	endif
endif

include $(TOOLCHAIN_DIR)$(PLATFORM).$(ARCH).toolchain.mk

AR?=ar
CC?=clang
MKDIR?=mkdir -p
CP?=cp
ECHO?=echo
MAKE?=make
CAT?=cat
RM?=rm -rf
GIT?=git
CD?=cd

VERSION:=$(shell $(CD) $(CURRENT_DIR) && $(GIT) name-rev --tags --name-only --always --no-undefined $(shell $(GIT) rev-parse HEAD))
PROJECT_NAME:=$(lastword $(subst /, ,$(CURRENT_DIR)))

export ROOT_DIR?=$(CURRENT_DIR)
export ROOT_BUILD_DIR?=$(ROOT_DIR)build/
export ROOT_BUILD_BIN_DIR?=$(ROOT_BUILD_DIR)bin/
export ROOT_BUILD_INCLUDE_DIR?=$(ROOT_BUILD_DIR)include/
export ROOT_BUILD_LIB_DIR?=$(ROOT_BUILD_DIR)lib/
export ROOT_DEPENDENCIES_FILE?=$(ROOT_BUILD_LIB_DIR)$(PROJECT_NAME).$(VERSION).DEPENDENCIES
export ROOT_LINK_FILE?=$(ROOT_BUILD_LIB_DIR)$(PROJECT_NAME).$(VERSION).LINK
export ROOT_DISTRIBUTED_INCLUDE_DIR:=$(ROOT_BUILD_INCLUDE_DIR)$(PROJECT_NAME)/$(VERSION)/

override CFLAGS+=-Wall -Wextra
override DEFINES+=VERSION=$(VERSION)
override DEBUG_CFLAGS+=-O0 -g -DDEBUG
override RELEASE_CFLAGS+=-02 -DRELEASE

lib_source_files:=$(wildcard $(SOURCE_LIB_DIR)*.c)
bin_sources_files=$(wildcard $(SOURCE_BIN_DIR)*.c)
include_files:=$(wildcard $(INCLUDE_DIR)*.h)
lib_object_files:= $(lib_source_files:$(SOURCE_LIB_DIR)%.c=$(GEN_DIR)%.o)
cube_makefiles:=$(wildcard $(CUBE_DIR)*/Makefile)
bin_files:=$(bin_sources_files:$(SOURCE_BIN_DIR)%.c=$(ROOT_BUILD_BIN_DIR)%.${VERSION})
lib_file:=$(if $(lib_object_files),$(ROOT_BUILD_LIB_DIR)lib$(PROJECT_NAME).${VERSION}.a)
distributed_include_files:=$(include_files:$(INCLUDE_DIR)%.h=$(ROOT_DISTRIBUTED_INCLUDE_DIR)%.h)
link_file:=$(LINK_DIR)$(PLATFORM).link

reverse=$(if $(1),$(call reverse,$(wordlist 2,$(words $(1)),$(1)))) $(firstword $(1))

default: debug
.PHONY: default

release: CFLAGS+=$(RELEASE_CFLAGS)
release: build_cube_release $(distributed_include_files) $(lib_file) $(bin_files)
.PHONY: release

debug: CFLAGS+=$(DEBUG_CFLAGS)
debug: build_cube_debug $(distributed_include_files) $(lib_file) $(bin_files)
.PHONY: debug

build_cube_release:
	$(foreach makefile, $(cube_makefiles), $(MAKE) -f $(makefile) release;)
.PHONY: build_cube_release
.NOTPARALLEL: build_cube_release

build_cube_debug:
	$(foreach makefile, $(cube_makefiles), $(MAKE) -f $(makefile) debug;)
.PHONY: build_cube_debug
.NOTPARALLEL: build_cube_debug

clean_cube:
	$(foreach makefile, $(cube_makefiles), $(MAKE) -f $(makefile) clean;)
.PHONY: clean_cube

clean: clean_cube
	$(RM) $(lib_object_files)
ifeq ($(ROOT_DIR),$(CURRENT_DIR))
	$(RM) $(ROOT_BUILD_INCLUDE_DIR)* $(ROOT_BUILD_BIN_DIR)* $(ROOT_BUILD_LIB_DIR)*
endif
.PHONY: clean

$(ROOT_DISTRIBUTED_INCLUDE_DIR)%.h: $(INCLUDE_DIR)%.h
	@$(ECHO) "Export $@"
	@$(MKDIR) $(ROOT_DISTRIBUTED_INCLUDE_DIR)
	@$(CP) $< $@

$(ROOT_BUILD_BIN_DIR)%.$(VERSION): $(SOURCE_BIN_DIR)%.c $(lib_file) $(distributed_include_files) $(ROOT_DEPENDENCIES_FILE)
	$(CC) $(CFLAGS) $(DEFINES:%=-D%) $< $(call reverse,$(shell $(CAT) $(ROOT_DEPENDENCIES_FILE))) -o $@ -I$(ROOT_BUILD_INCLUDE_DIR) -I$(INCLUDE_DIR) $(addprefix -l,$(shell $(CAT) $(ROOT_LINK_FILE)))

$(lib_file): $(lib_object_files) $(ROOT_DEPENDENCIES_FILE) $(link_file) $(ROOT_LINK_FILE)
	$(AR) rcs $@ $(lib_object_files)
	$(if $(findstring $@,$(shell $(CAT) $(ROOT_DEPENDENCIES_FILE))),,@$(ECHO) "$@" >> $(ROOT_DEPENDENCIES_FILE))
	$(foreach lib, $(shell $(CAT) $(link_file)), $(if $(findstring $(lib),$(shell $(CAT) $(ROOT_LINK_FILE))),,@$(ECHO) "$(lib)" >> $(ROOT_LINK_FILE)))

$(GEN_DIR)%.o: $(SOURCE_LIB_DIR)%.c $(distributed_include_files)
	$(CC) $(CFLAGS) $(DEFINES:%=-D%) -c $< -o $@ -I$(ROOT_BUILD_INCLUDE_DIR) -I$(INCLUDE_DIR)

$(ROOT_DEPENDENCIES_FILE):
	@$(ECHO) "" > $@

$(ROOT_LINK_FILE):
	@$(ECHO) "" > $@