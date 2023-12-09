# --- CRAB MAKEFILE ---
# Zero-configuration modular makefile.
# Library, binary & header files are exported to the root project.

ifdef OS 
	# Windows
	/:=\\
	LIB_SUFFIX:=lib
else 
	# Unix-like
	/:=/
	LIB_SUFFIX:=a
endif

AR?=ar
CC?=clang
MKDIR?=mkdir -p
CP?=cp
ECHO?=echo

CFLAGS?=-Wall -Wextra

export ROOT_DIR?=$(dir $(realpath $(firstword $(MAKEFILE_LIST))))
export ROOT_BUILD_DIR?=$(ROOT_DIR)build$(/)
export ROOT_BUILD_BIN_DIR?=$(ROOT_BUILD_DIR)bin$(/)
export ROOT_BUILD_INCLUDE_DIR?=$(ROOT_BUILD_DIR)includes$(/)
export ROOT_BUILD_LIB_DIR?=$(ROOT_BUILD_DIR)lib$(/)

CURRENT_DIR:=$(dir $(realpath $(firstword $(MAKEFILE_LIST))))
PROJECT_NAME:=$(lastword $(subst $(/), ,$(CURRENT_DIR)))
INCLUDE_DIR:=$(CURRENT_DIR)include$(/)
SOURCE_DIR:=$(CURRENT_DIR)source$(/)
SOURCE_BIN_DIR:=$(SOURCE_DIR)bin$(/)
SOURCE_LIB_DIR:=$(SOURCE_DIR)lib$(/)
GEN_DIR:=$(CURRENT_DIR)gen$(/)
DISTRIBUTED_INCLUDE_DIR:=$(ROOT_BUILD_INCLUDE_DIR)$(PROJECT_NAME)$(/)

DEBUG_CFLAGS:=-O0 -g -DDEBUG
RELEASE_CFLAGS:=-02 -DRELEASE

lib_source_files:=$(wildcard $(SOURCE_LIB_DIR)*.c)
bin_sources_files=$(wildcard $(SOURCE_BIN_DIR)*.c)
include_files:=$(wildcard $(INCLUDE_DIR)*.h)
lib_object_files:= $(lib_source_files:$(SOURCE_LIB_DIR)%.c=$(GEN_DIR)%.o)
bin_files:=$(bin_sources_files:$(SOURCE_BIN_DIR)%.c=$(ROOT_BUILD_BIN_DIR)%)
lib_file:=$(ROOT_BUILD_LIB_DIR)lib$(PROJECT_NAME).$(LIB_SUFFIX)
distributed_include_files:=$(include_files:$(INCLUDE_DIR)%.h=$(DISTRIBUTED_INCLUDE_DIR)%.h)

default: debug
.PHONY: default

release: CFLAGS+=$(RELEASE_CFLAGS)
release: $(distributed_include_files) $(lib_file) $(bin_files)
.PHONY: release

debug: CFLAGS+=$(DEBUG_CFLAGS)
debug: $(distributed_include_files) $(lib_file) $(bin_files)
.PHONY: debug

clean:
	@$(ECHO) "Remove generated files"
	@$(RM) $(lib_object_files) $(bin_files) $(lib_file)
.PHONY: debug

$(DISTRIBUTED_INCLUDE_DIR)%.h: $(INCLUDE_DIR)%.h
	@$(ECHO) "Export $@"
	@$(MKDIR) $(DISTRIBUTED_INCLUDE_DIR)
	@$(CP) $< $@

$(ROOT_BUILD_BIN_DIR)%: $(SOURCE_BIN_DIR)%.c $(lib_file) $(distributed_include_files)
	$(CC) $(CFLAGS) $< $(wildcard $(ROOT_BUILD_LIB_DIR)lib*.$(LIB_SUFFIX)) -o $@ -I$(ROOT_BUILD_INCLUDE_DIR)

$(lib_file): $(lib_object_files)
	$(AR) rcs $@ $^

$(GEN_DIR)%.o: $(SOURCE_LIB_DIR)%.c $(distributed_include_files)
	$(CC) $(CFLAGS) -c $< -o $@ -I$(ROOT_BUILD_INCLUDE_DIR)