#-------------------------------------------------------------------------------
#
#  Copyright (C) 2024 Abhisit Sangjan <abhisit.sangjan@gmail.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of ncurses
#

NCURSES_VERSION		= 6.5
NCURSES_TARBALL		= ncurses-$(NCURSES_VERSION).tar.gz
NCURSES_TARBALL_URLS	+= $(ONIE_MIRROR) \
			   https://ftp.gnu.org/pub/gnu/ncurses
NCURSES_BUILD_DIR	=  $(USER_BUILDDIR)/ncurses
NCURSES_DIR		=  $(NCURSES_BUILD_DIR)/ncurses-$(NCURSES_VERSION)

NCURSES_SRCPATCHDIR	= $(PATCHDIR)/ncurses
NCURSES_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/ncurses-download
NCURSES_SOURCE_STAMP	= $(USER_STAMPDIR)/ncurses-source
NCURSES_CONFIGURE_STAMP	= $(USER_STAMPDIR)/ncurses-configure
NCURSES_BUILD_STAMP	= $(USER_STAMPDIR)/ncurses-build
NCURSES_INSTALL_STAMP	= $(STAMPDIR)/ncurses-install
NCURSES_STAMP		= $(NCURSES_DOWNLOAD_STAMP) \
			  $(NCURSES_SOURCE_STAMP) \
			  $(NCURSES_PATCH_STAMP) \
			  $(NCURSES_CONFIGURE_STAMP) \
			  $(NCURSES_BUILD_STAMP) \
			  $(NCURSES_INSTALL_STAMP)

PHONY += ncurses \
	 ncurses-download \
	 ncurses-source \
	 ncurses-configure \
	 ncurses-build \
	 ncurses-install \
	 ncurses-clean \
	 ncurses-download-clean

ncurses: $(NCURSES_STAMP)

DOWNLOAD += $(NCURSES_DOWNLOAD_STAMP)

ncurses-download: $(NCURSES_DOWNLOAD_STAMP)
$(NCURSES_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream ncurses ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(NCURSES_TARBALL) $(NCURSES_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(NCURSES_SOURCE_STAMP)

ncurses-source: $(NCURSES_SOURCE_STAMP)
$(NCURSES_SOURCE_STAMP): $(USER_TREE_STAMP) | $(NCURSES_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream ncurses ===="
	$(Q) mkdir -p $(NCURSES_BUILD_DIR)
	$(Q) $(SCRIPTDIR)/extract-package $(NCURSES_BUILD_DIR) $(DOWNLOADDIR)/$(NCURSES_TARBALL)
	$(Q) touch $@

ifndef MAKE_CLEAN
NCURSES_NEW_FILES = $( \
			shell test -d $(NCURSES_DIR) && \
			test -f $(NCURSES_BUILD_STAMP) && \
			find -L $(NCURSES_DIR) -newer $(NCURSES_BUILD_STAMP) -type f -print -quit \
		)
endif

ncurses-configure: $(NCURSES_CONFIGURE_STAMP)
$(NCURSES_CONFIGURE_STAMP): $(NCURSES_PATCH_STAMP) $(OPENSSL_INSTALL_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure ncurses-$(NCURSES_VERSION) ===="
#	$(Q) cd $(NCURSES_DIR) && /bin/bash
	$(Q) cd $(NCURSES_DIR) &&		\
		$(NCURSES_DIR)/configure	\
		--host=$(TARGET)		\
		--prefix=/usr			\
		--with-shared			\
		--without-cxx-shared		\
		--without-debug			\
		--without-ada
	$(Q) touch $@

ncurses-build: $(NCURSES_BUILD_STAMP)
$(NCURSES_BUILD_STAMP): $(NCURSES_CONFIGURE_STAMP) $(NCURSES_NEW_FILES) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building ncurses-$(NCURSES_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'						\
		$(MAKE) -C $(NCURSES_DIR)					\
		CC=$(CROSSPREFIX)gcc						\
		CFLAGS="$(ONIE_CFLAGS) -I $(DEV_SYSROOT)/usr/include"
#	$(Q) PATH='$(CROSSBIN):$(PATH)'						\
#		$(MAKE) -C $(NCURSES_DIR) install DESTDIR=$(DEV_SYSROOT)	\
#		CC=$(CROSSPREFIX)gcc
	$(Q) touch $@

ncurses-install: $(NCURSES_INSTALL_STAMP)
$(NCURSES_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(NCURSES_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing ncurses in $(SYSROOTDIR) ===="
	$(Q) mkdir -p $(SYSROOTDIR)/usr/bin/
	$(Q) cp -av $(DEV_SYSROOT)/usr/bin/ncurses $(SYSROOTDIR)/usr/bin/
	$(Q) touch $@

USER_CLEAN += ncurses-clean
ncurses-clean:
	$(Q) rm -rf $(NCURSES_BUILD_DIR)
	$(Q) rm -f $(NCURSES_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += ncurses-download-clean
ncurses-download-clean:
	$(Q) rm -f $(NCURSES_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(NCURSES_TARBALL)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End: