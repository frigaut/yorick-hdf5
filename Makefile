# $Id: Makefile,v 1.3 2008-11-21 16:19:17 frigaut Exp $
Y_MAKEDIR=/home/frigaut/yorick-2.1.05x
Y_EXE=/home/frigaut/yorick-2.1.05x/bin/yorick
Y_EXE_PKGS=
Y_EXE_HOME=/home/frigaut/yorick-2.1.05x
Y_EXE_SITE=/home/frigaut/yorick-2.1.05x

# ----------------------------------------------------- optimization flags

COPT=$(COPT_DEFAULT)
TGT=$(DEFAULT_TGT)

# ------------------------------------------------ macros for this package

PKG_NAME=hdf5
PKG_I=hdf5.i h5scan_fromshell.i h5convert_fromshell.i

OBJS=hdf5.o

# change to give the executable a name other than yorick
PKG_EXENAME=yorick

# PKG_DEPLIBS=-Lsomedir -lsomelib   for dependencies of this package
PKG_DEPLIBS=-lhdf5 -lz
# set compiler or loader (rare) flags specific to this package
# yorick-hdf5 was written for hdf5 v1.6. Some distro (e.g. f9) have
# moved to v1.8, which has incompatible APIs. Fortunately, hdf5
# developers have provided a way to expose the v1.6 APIs:
PKG_CFLAGS=-D H5_USE_16_API
PKG_LDFLAGS=-D H5_USE_16_API
# another solution is to build hdf5 v1.6 (e.g. in /usr/local) and
# use this:
# PKG_CFLAGS=-I/usr/local/include
# PKG_LDFLAGS=-L/usr/local/lib -lhdf5 -Wl,--rpath=/usr/local/lib

# list of additional package names you want in PKG_EXENAME
# (typically Y_EXE_PKGS should be first here)
EXTRA_PKGS=$(Y_EXE_PKGS)

# list of additional files for clean
PKG_CLEAN=

# autoload file for this package, if any
PKG_I_START=hdf5_start.i

# -------------------------------- standard targets and rules (in Makepkg)

# set macros Makepkg uses in target and dependency names
# DLL_TARGETS, LIB_TARGETS, EXE_TARGETS
# are any additional targets (defined below) prerequisite to
# the plugin library, archive library, and executable, respectively
PKG_I_DEPS=$(PKG_I)

include $(Y_MAKEDIR)/Make.cfg
include $(Y_MAKEDIR)/Makepkg
include $(Y_MAKEDIR)/Make$(TGT)

# override macros Makepkg sets for rules and other macros
# Y_HOME and Y_SITE in Make.cfg may not be correct (e.g.- relocatable)
Y_HOME=$(Y_EXE_HOME)
Y_SITE=$(Y_EXE_SITE)

# reduce chance of yorick-1.5 corrupting this Makefile
MAKE_TEMPLATE = protect-against-1.5

# ------------------------------------- targets and rules for this package

# simple example:
#myfunc.o: myapi.h
# more complex example (also consider using PKG_CFLAGS above):
#myfunc.o: myapi.h myfunc.c
#	$(CC) $(CPPFLAGS) $(CFLAGS) -DMY_SWITCH -o $@ -c myfunc.c

clean::
	-rm -rf binaries

# -------------------------------------------------------- end of Makefile


# for the binary package production (add full path to lib*.a below):
# macosx:
PKG_DEPLIBS_STATIC=-lm -lz /usr/lib/libhdf5.a
PKG_ARCH = $(OSTYPE)-$(MACHTYPE)
# or linux or windows
PKG_VERSION = $(shell (awk '{if ($$1=="Version:") print $$2}' $(PKG_NAME).info))
# .info might not exist, in which case he line above will exit in error.

# packages or devel_pkgs:
PKG_DEST_URL = packages

package:
	$(MAKE)
	$(LD_DLL) -o $(PKG_NAME).so $(OBJS) ywrap.o $(PKG_DEPLIBS_STATIC) $(DLL_DEF)
	mkdir -p binaries/$(PKG_NAME)/dist/y_home/lib
	mkdir -p binaries/$(PKG_NAME)/dist/y_home/i-start
	mkdir -p binaries/$(PKG_NAME)/dist/y_site/i0
	mkdir -p binaries/$(PKG_NAME)/dist/y_home/bin
	cp -p $(PKG_I) binaries/$(PKG_NAME)/dist/y_site/i0/
	cp -p $(PKG_NAME).so binaries/$(PKG_NAME)/dist/y_home/lib/
	cp -p h5info binaries/$(PKG_NAME)/dist/y_home/bin/.
	cp -p h5convert binaries/$(PKG_NAME)/dist/y_home/bin/.
	if test -f "check.i"; then cp -p check.i binaries/$(PKG_NAME)/.; fi
	if test -n "$(PKG_I_START)"; then cp -p $(PKG_I_START) \
	  binaries/$(PKG_NAME)/dist/y_home/i-start/; fi
	cat $(PKG_NAME).info | sed -e 's/OS:/OS: $(PKG_ARCH)/' > tmp.info
	mv tmp.info binaries/$(PKG_NAME)/$(PKG_NAME).info
	cd binaries; tar zcvf $(PKG_NAME)-$(PKG_VERSION)-$(PKG_ARCH).tgz $(PKG_NAME)

distbin: package
	if test -f "binaries/$(PKG_NAME)-$(PKG_VERSION)-$(PKG_ARCH).tgz" ; then \
	  ncftpput -f $(HOME)/.ncftp/maumae www/yorick/$(PKG_DEST_URL)/$(PKG_ARCH)/tarballs/ \
	  binaries/$(PKG_NAME)-$(PKG_VERSION)-$(PKG_ARCH).tgz; fi
	if test -f "binaries/$(PKG_NAME)/$(PKG_NAME).info" ; then \
	  ncftpput -f $(HOME)/.ncftp/maumae www/yorick/$(PKG_DEST_URL)/$(PKG_ARCH)/info/ \
	  binaries/$(PKG_NAME)/$(PKG_NAME).info; fi

distsrc:
	make clean; rm -rf binaries
	cd ..; tar --exclude binaries --exclude .svn --exclude CVS --exclude *.spec -zcvf \
	   $(PKG_NAME)-$(PKG_VERSION)-src.tgz yorick-$(PKG_NAME)-$(PKG_VERSION);\
	ncftpput -f $(HOME)/.ncftp/maumae www/yorick/$(PKG_DEST_URL)/src/ \
	   $(PKG_NAME)-$(PKG_VERSION)-src.tgz
	cd ..; ncftpput -f $(HOME)/.ncftp/maumae www/yorick/contrib/ \
	   $(PKG_NAME)-$(PKG_VERSION)-src.tgz


# -------------------------------------------------------- end of Makefile
