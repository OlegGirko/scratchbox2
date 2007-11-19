# Copyright (C) 2007 Lauri Leukkunen <lle@rahina.org>
# Licensed under LGPL 2.1

TOPDIR = $(CURDIR)
OBJDIR = $(TOPDIR)
SRCDIR = $(TOPDIR)
VPATH = $(SRCDIR)


ifeq ($(MAKECMDGOALS),install-multilib)
BUILD_TARGET=multilib
else
BUILD_TARGET=$(targets)
endif

ifeq ($(shell uname -m),x86_64)
PRI_OBJDIR = obj-64
else
PRI_OBJDIR = obj-32
endif


CC = gcc
CXX = g++
LD = ld
PACKAGE_VERSION = "1.99.0.19"
PACKAGE = "SB2"
LIBSB2_SONAME = "libsb2.so.1"
LLBUILD ?= $(SRCDIR)/llbuild


# targets variable will be filled by llbuild
targets = 
subdirs = luaif preload utils

-include config.mak

CFLAGS += -O2 -g -Wall -W
CFLAGS += -I$(OBJDIR)/include -I$(SRCDIR)/include
CFLAGS += -I$(SRCDIR)/luaif/lua-5.1.2/src
CFLAGS += -D_GNU_SOURCE=1 -D_LARGEFILE_SOURCE=1 -D_LARGEFILE64_SOURCE=1
CFLAGS += -DSCRATCHBOX_ROOT="$(prefix)"
CXXFLAGS = 

include $(LLBUILD)/Makefile.include

export CC CFLAGS LDFLAGS CXX CXXFLAGS TOPDIR LLBUILD

ifdef prefix
CONFIGURE_ARGS = --prefix=$(prefix)
else
CONFIGURE_ARGS = 
endif


all: $(targets)


multilib:
	rm -rf obj-32 obj-64
	mkdir -p obj-32
	mkdir -p obj-64
	
	cd obj-32 && \
	CFLAGS=-m32 LDFLAGS=-m32 ../configure $(CONFIGURE_ARGS) && \
	$(MAKE) --include-dir=.. -f ../Makefile SRCDIR=..

	cd obj-64 && \
	CFLAGS=-m64 LDFLAGS=-m64 ../configure $(CONFIGURE_ARGS) && \
	$(MAKE) --include-dir=.. -f ../Makefile SRCDIR=..


gcc_bins = addr2line ar as cc c++ c++filt cpp g++ gcc gcov gdb gdbtui gprof ld nm objcopy objdump ranlib rdi-stub readelf run size strings strip
gcc_bins_expanded = $(foreach v,$(gcc_bins),$(prefix)/bin/host-$(v))


sources-release:
	git archive --format=tar --prefix=sbox2-$(PACKAGE_VERSION)/ $(PACKAGE_VERSION) | bzip2 >sbox2-$(PACKAGE_VERSION).tar.bz2


install-noarch: $(BUILD_TARGET)
	install -d -m 755 $(prefix)/bin
	install -d -m 755 $(prefix)/share/scratchbox2/lua_scripts
	install -d -m 755 $(prefix)/share/scratchbox2/lua_scripts/pathmaps
	install -d -m 755 $(prefix)/share/scratchbox2/lua_scripts/pathmaps/complex
	install -d -m 755 $(prefix)/share/scratchbox2/lua_scripts/pathmaps/emulate
	install -d -m 755 $(prefix)/share/scratchbox2/lua_scripts/pathmaps/simple
	install -d -m 755 $(prefix)/share/scratchbox2/scripts
	install -d -m 755 $(prefix)/share/scratchbox2/tests
	install -d -m 755 $(prefix)/share/man/man1
	echo "$(PACKAGE_VERSION)" > $(prefix)/share/scratchbox2/version
	install -c -m 755 $(SRCDIR)/utils/sb2 $(prefix)/bin/sb2
	install -c -m 755 $(SRCDIR)/utils/sb2-init $(prefix)/bin/sb2-init
	install -c -m 755 $(SRCDIR)/utils/sb2-config $(prefix)/bin/sb2-config
	install -c -m 755 $(SRCDIR)/utils/sb2-build-libtool $(prefix)/bin/sb2-build-libtool
	install -c -m 755 $(SRCDIR)/utils/dpkg-checkbuilddeps $(prefix)/share/scratchbox2/scripts/dpkg-checkbuilddeps
	install -c -m 755 $(SRCDIR)/utils/dpkg-architecture $(prefix)/share/scratchbox2/scripts/dpkg-architecture
	install -c -m 644 $(SRCDIR)/lua_scripts/mapping.lua $(prefix)/share/scratchbox2/lua_scripts/mapping.lua
	install -c -m 644 $(SRCDIR)/lua_scripts/pathmaps/complex/*.lua $(prefix)/share/scratchbox2/lua_scripts/pathmaps/complex/
	install -c -m 644 $(SRCDIR)/lua_scripts/pathmaps/emulate/*.lua $(prefix)/share/scratchbox2/lua_scripts/pathmaps/emulate/
	install -c -m 644 $(SRCDIR)/lua_scripts/pathmaps/simple/*.lua $(prefix)/share/scratchbox2/lua_scripts/pathmaps/simple/
	install -c -m 644 $(SRCDIR)/tests/* $(prefix)/share/scratchbox2/tests
	chmod a+x $(prefix)/share/scratchbox2/tests/run.sh

	install -c -m 644 $(SRCDIR)/docs/sb2.1 $(prefix)/share/man/man1/sb2.1
	rm -f $(prefix)/share/scratchbox2/host_usr
	ln -sf /usr $(prefix)/share/scratchbox2/host_usr


# remember to keep install and install-multilib in sync!
install: install-noarch
	install -d -m 755 $(prefix)/lib
	install -d -m 755 $(prefix)/lib/libsb2
	install -c -m 755 $(OBJDIR)/preload/libsb2.so $(prefix)/lib/libsb2/libsb2.so.$(PACKAGE_VERSION)
	install -c -m 755 $(OBJDIR)/utils/sb_gcc_wrapper $(prefix)/bin/sb_gcc_wrapper
	@for f in $(gcc_bins_expanded); do \
		ln -sf sb_gcc_wrapper $$f; \
	done
	/sbin/ldconfig -n $(prefix)/lib/libsb2


install-multilib: install-noarch
	install -d -m 755 $(prefix)/lib32
	install -d -m 755 $(prefix)/lib32/libsb2
	install -d -m 755 $(prefix)/lib64
	install -d -m 755 $(prefix)/lib64/libsb2
	install -c -m 755 obj-32/preload/libsb2.so $(prefix)/lib32/libsb2/libsb2.so.$(PACKAGE_VERSION)
	install -c -m 755 obj-64/preload/libsb2.so $(prefix)/lib64/libsb2/libsb2.so.$(PACKAGE_VERSION)
	install -c -m 755 $(PRI_OBJDIR)/utils/sb_gcc_wrapper $(prefix)/bin/sb_gcc_wrapper
	@for f in $(gcc_bins_expanded); do \
		ln -sf sb_gcc_wrapper $$f; \
	done
	/sbin/ldconfig -n $(prefix)/lib32/libsb2 $(prefix)/lib64/libsb2


CLEAN_FILES += $(targets) config.status config.log

# make all object files depend on include/config.h

clean:
	$(ll_clean)

