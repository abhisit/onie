#-------------------------------------------------------------------------------
#
#  Copyright (C) 2024 Abhisit Sangjan <abhisit.sangjan@gmail.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of fwupd
#

FWUPD_VERSION		= 2.0.3
FWUPD_TARBALL		= fwupd-$(FWUPD_VERSION).tar.xz
FWUPD_TARBALL_URLS	+= $(ONIE_MIRROR) \
			   https://github.com/fwupd/fwupd/releases/download/$(FWUPD_VERSION)
FWUPD_BUILD_DIR		= $(USER_BUILDDIR)/fwupd
FWUPD_DIR		= $(FWUPD_BUILD_DIR)/fwupd-$(FWUPD_VERSION)

FWUPD_SRCPATCHDIR	= $(PATCHDIR)/fwupd
FWUPD_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/fwupd-download
FWUPD_SOURCE_STAMP	= $(USER_STAMPDIR)/fwupd-source
FWUPD_BUILD_STAMP	= $(USER_STAMPDIR)/fwupd-build
FWUPD_INSTALL_STAMP	= $(STAMPDIR)/fwupd-install
FWUPD_STAMP		= $(FWUPD_DOWNLOAD_STAMP) \
			  $(FWUPD_SOURCE_STAMP) \
			  $(FWUPD_PATCH_STAMP) \
			  $(FWUPD_BUILD_STAMP) \
			  $(FWUPD_INSTALL_STAMP)

PHONY += fwupd \
	 fwupd-download \
	 fwupd-source \
	 fwupd-build \
	 fwupd-install \
	 fwupd-clean \
	 fwupd-download-clean

fwupd: $(FWUPD_STAMP)

DOWNLOAD += $(FWUPD_DOWNLOAD_STAMP)

fwupd-download: $(FWUPD_DOWNLOAD_STAMP)
$(FWUPD_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream fwupd ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(FWUPD_TARBALL) $(FWUPD_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(FWUPD_SOURCE_STAMP)

fwupd-source: $(FWUPD_SOURCE_STAMP)
$(FWUPD_SOURCE_STAMP): $(USER_FWUPD_STAMP) | $(FWUPD_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream fwupd ===="
	$(Q) $(SCRIPTDIR)/extract-package $(FWUPD_BUILD_DIR) $(DOWNLOADDIR)/$(FWUPD_TARBALL)
	$(Q) touch $@

ifndef MAKE_CLEAN
FWUPD_NEW_FILES = $( \
			shell test -d $(FWUPD_DIR) && \
			test -f $(FWUPD_BUILD_STAMP) && \
			find -L $(FWUPD_DIR) -newer $(FWUPD_BUILD_STAMP) -type f -print -quit \
		)
endif

fwupd-build: $(FWUPD_BUILD_STAMP)
$(FWUPD_BUILD_STAMP): $(FWUPD_PATCH_STAMP) $(FWUPD_NEW_FILES) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building fwupd-$(FWUPD_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)' && cd $(FWUPD_DIR) && \
		source ./contrib/setup
#	$(Q) touch $@

fwupd-install: $(FWUPD_INSTALL_STAMP)
$(FWUPD_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(FWUPD_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing fwupd in $(SYSROOTDIR) ===="
	$(Q) mkdir -p $(SYSROOTDIR)/usr/bin/
	$(Q) cp -av $(FWUPD_DIR)/fwupd $(SYSROOTDIR)/usr/bin/
	$(Q) touch $@

USER_CLEAN += fwupd-clean
fwupd-clean:
	$(Q) rm -rf $(FWUPD_BUILD_DIR)
	$(Q) rm -f $(FWUPD_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += fwupd-download-clean
fwupd-download-clean:
	$(Q) rm -f $(FWUPD_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(FWUPD_TARBALL)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
