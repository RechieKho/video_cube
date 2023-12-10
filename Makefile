# --- CUBE MAKEFILE ---
# Zero-configuration modular makefile.
# Library, binary & header files are exported to the root project.

ifdef OS 
	# Windows
	/:=\\
else 
	# Unix-like
	/:=/
endif

AR:=ar
CC:=clang
MKDIR:=mkdir -p
CP:=cp
ECHO:=echo
MAKE:=make
CAT:=cat
RM:=rm -rf
GIT:=git

export ROOT_DIR?=$(dir $(realpath $(firstword $(MAKEFILE_LIST))))
export ROOT_BUILD_DIR?=$(ROOT_DIR)build$(/)
export ROOT_BUILD_BIN_DIR?=$(ROOT_BUILD_DIR)bin$(/)
export ROOT_BUILD_INCLUDE_DIR?=$(ROOT_BUILD_DIR)include$(/)
export ROOT_BUILD_LIB_DIR?=$(ROOT_BUILD_DIR)lib$(/)
export ROOT_DEPENDENCIES_FILE?=$(ROOT_BUILD_LIB_DIR)DEPENDENCIES

VERSION:=$(shell $(GIT) name-rev --tags --name-only --always --no-undefined $(shell $(GIT) rev-parse HEAD))

CURRENT_DIR:=$(dir $(realpath $(firstword $(MAKEFILE_LIST))))
PROJECT_NAME:=$(lastword $(subst $(/), ,$(CURRENT_DIR)))
INCLUDE_DIR:=$(CURRENT_DIR)include$(/)
SOURCE_DIR:=$(CURRENT_DIR)source$(/)
SOURCE_BIN_DIR:=$(SOURCE_DIR)bin$(/)
SOURCE_LIB_DIR:=$(SOURCE_DIR)lib$(/)
GEN_DIR:=$(CURRENT_DIR)gen$(/)
CUBE_DIR:=$(CURRENT_DIR)cube$(/)
DISTRIBUTED_INCLUDE_DIR:=$(ROOT_BUILD_INCLUDE_DIR)$(PROJECT_NAME)$(/)$(VERSION)$(/)

override CFLAGS+=-Wall -Wextra
override DEFINES+=VERSION=$(VERSION)
override DEBUG_CFLAGS+=-O0 -g -DDEBUG
override RELEASE_CFLAGS+=-02 -DRELEASE

lib_source_files:=$(wildcard $(SOURCE_LIB_DIR)*.c)
bin_sources_files=$(wildcard $(SOURCE_BIN_DIR)*.c)
include_files:=$(wildcard $(INCLUDE_DIR)*.h)
lib_object_files:= $(lib_source_files:$(SOURCE_LIB_DIR)%.c=$(GEN_DIR)%.o)
cube_makefiles:=$(wildcard $(CUBE_DIR)*$(/)Makefile)
bin_files:=$(bin_sources_files:$(SOURCE_BIN_DIR)%.c=$(ROOT_BUILD_BIN_DIR)%.${VERSION})
lib_file:=$(if $(lib_object_files),$(ROOT_BUILD_LIB_DIR)lib$(PROJECT_NAME).${VERSION}.a)
distributed_include_files:=$(include_files:$(INCLUDE_DIR)%.h=$(DISTRIBUTED_INCLUDE_DIR)%.h)

reverse=$(if $(1),$(call reverse,$(wordlist 2,$(words $(1)),$(1)))) $(firstword $(1))

default: debug
.PHONY: default

release: CFLAGS+=$(RELEASE_CFLAGS)
release: build_cube_release $(distributed_include_files) $(lib_file) $(bin_files)
	@$(RM) $(ROOT_DEPENDENCIES_FILE)
.PHONY: release

debug: CFLAGS+=$(DEBUG_CFLAGS)
debug: build_cube_debug $(distributed_include_files) $(lib_file) $(bin_files)
	@$(RM) $(ROOT_DEPENDENCIES_FILE)
.PHONY: debug

build_cube_release:
	$(foreach makefile, $(cube_makefiles), $(MAKE) -f $(makefile) release;)
.PHONY: build_cube

build_cube_debug:
	$(foreach makefile, $(cube_makefiles), $(MAKE) -f $(makefile) debug;)
.PHONY: build_cube

clean_cube:
	$(foreach makefile, $(cube_makefiles), $(MAKE) -f $(makefile) clean;)

clean: clean_cube
	$(RM) $(lib_object_files)
ifeq ($(ROOT_DIR),$(CURRENT_DIR))
	$(RM) $(ROOT_BUILD_INCLUDE_DIR)* $(ROOT_BUILD_BIN_DIR)* $(ROOT_BUILD_LIB_DIR)*
endif
.PHONY: debug

$(DISTRIBUTED_INCLUDE_DIR)%.h: $(INCLUDE_DIR)%.h
	@$(ECHO) "Export $@"
	@$(MKDIR) $(DISTRIBUTED_INCLUDE_DIR)
	@$(CP) $< $@

$(ROOT_BUILD_BIN_DIR)%.$(VERSION): $(SOURCE_BIN_DIR)%.c $(lib_file) $(distributed_include_files)
	$(CC) $(CFLAGS) $(DEFINES:%=-D%) $< $(call reverse,$(shell $(CAT) $(ROOT_DEPENDENCIES_FILE))) -o $@ -I$(ROOT_BUILD_INCLUDE_DIR) -I$(INCLUDE_DIR)

$(lib_file): $(lib_object_files)
	$(AR) rcs $@ $^
	@$(ECHO) "$@" >> $(ROOT_DEPENDENCIES_FILE)

$(GEN_DIR)%.o: $(SOURCE_LIB_DIR)%.c $(distributed_include_files)
	$(CC) $(CFLAGS) $(DEFINES:%=-D%) -c $< -o $@ -I$(ROOT_BUILD_INCLUDE_DIR) -I$(INCLUDE_DIR)