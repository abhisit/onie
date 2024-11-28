#-------------------------------------------------------------------------------
#
#  Copyright (C) 2024 Abhisit Sangjan <abhisit.sangjan@gmail.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of libevent
#

LIBEVENT_VERSION		= 2.1.12-stable
LIBEVENT_TARBALL		= libevent-$(LIBEVENT_VERSION).tar.gz
LIBEVENT_TARBALL_URLS		+= $(ONIE_MIRROR) \
				   https://github.com/libevent/libevent/releases/download/release-$(LIBEVENT_VERSION)
LIBEVENT_BUILD_DIR		= $(USER_BUILDDIR)/libevent
LIBEVENT_DIR			= $(LIBEVENT_BUILD_DIR)/libevent-$(LIBEVENT_VERSION)

LIBEVENT_DOWNLOAD_STAMP		= $(DOWNLOADDIR)/libevent-download
LIBEVENT_SOURCE_STAMP		= $(USER_STAMPDIR)/libevent-source
LIBEVENT_CONFIGURE_STAMP	= $(USER_STAMPDIR)/libevent-configure
LIBEVENT_BUILD_STAMP		= $(USER_STAMPDIR)/libevent-build
LIBEVENT_INSTALL_STAMP		= $(STAMPDIR)/libevent-install
LIBEVENT_STAMP			= $(LIBEVENT_DOWNLOAD_STAMP) \
				  $(LIBEVENT_SOURCE_STAMP) \
				  $(LIBEVENT_CONFIGURE_STAMP) \
				  $(LIBEVENT_BUILD_STAMP) \
				  $(LIBEVENT_INSTALL_STAMP)

PHONY += libevent \
	 libevent-download \
	 libevent-source \
	 libevent-configure \
	 libevent-build \
	 libevent-install \
	 libevent-clean \
	 libevent-download-clean

libevent: $(LIBEVENT_STAMP)

DOWNLOAD += $(LIBEVENT_DOWNLOAD_STAMP)

libevent-download: $(LIBEVENT_DOWNLOAD_STAMP)
$(LIBEVENT_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream libevent ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(LIBEVENT_TARBALL) $(LIBEVENT_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(LIBEVENT_SOURCE_STAMP)

libevent-source: $(LIBEVENT_SOURCE_STAMP)
$(LIBEVENT_SOURCE_STAMP): $(USER_TREE_STAMP) | $(LIBEVENT_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream libevent ===="
	$(Q) $(SCRIPTDIR)/extract-package $(LIBEVENT_BUILD_DIR) $(DOWNLOADDIR)/$(LIBEVENT_TARBALL)
	$(Q) touch $@

ifndef MAKE_CLEAN
LIBEVENT_NEW_FILES = $( \
			shell test -d $(LIBEVENT_DIR) && \
			test -f $(LIBEVENT_BUILD_STAMP) && \
			find -L $(LIBEVENT_DIR) -newer $(LIBEVENT_BUILD_STAMP) -type f -print -quit \
		)
endif

libevent-configure: $(LIBEVENT_CONFIGURE_STAMP)
$(LIBEVENT_CONFIGURE_STAMP): $(LIBEVENT_SOURCE_STAMP) $(OPENSSL_INSTALL_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure libevent-$(LIBEVENT_VERSION) ===="
	$(Q) cd $(LIBEVENT_DIR) && PATH='$(CROSSBIN):$(PATH)'		\
		$(LIBEVENT_DIR)/configure				\
		--host=$(TARGET)					\
		--prefix=/usr						\
		CFLAGS="$(ONIE_CFLAGS) -I $(DEV_SYSROOT)/usr/include"
	$(Q) touch $@

libevent-build: $(LIBEVENT_BUILD_STAMP)
$(LIBEVENT_BUILD_STAMP): $(LIBEVENT_CONFIGURE_STAMP) $(LIBEVENT_NEW_FILES) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building libevent-$(LIBEVENT_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'						\
		$(MAKE) -C $(LIBEVENT_DIR)					\
		CC=$(CROSSPREFIX)gcc						\
		CFLAGS="$(ONIE_CFLAGS) -I $(DEV_SYSROOT)/usr/include"
	$(Q) touch $@

libevent-install: $(LIBEVENT_INSTALL_STAMP)
$(LIBEVENT_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(LIBEVENT_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing libevent in $(SYSROOTDIR) ===="
	$(Q) mkdir -p $(SYSROOTDIR)/usr/bin/
	$(Q) cp -av -r $(LIBEVENT_DIR)/.libs/*.so* $(SYSROOTDIR)/usr/lib/
	$(Q) cp -av -r $(LIBEVENT_DIR)/.libs/*.so* $(DEV_SYSROOT)/usr/lib/
	$(Q) cp -av -r $(LIBEVENT_DIR)/.libs/*.a $(DEV_SYSROOT)/usr/lib/
	$(Q) cp -av -r $(LIBEVENT_DIR)/include/* $(DEV_SYSROOT)/usr/include/
	$(Q) touch $@

USER_CLEAN += libevent-clean
libevent-clean:
	$(Q) rm -rf $(LIBEVENT_BUILD_DIR)
	$(Q) rm -f $(LIBEVENT_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += libevent-download-clean
libevent-download-clean:
	$(Q) rm -f $(LIBEVENT_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(LIBEVENT_TARBALL)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
