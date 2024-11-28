#-------------------------------------------------------------------------------
#
#  Copyright (C) 2024 Abhisit Sangjan <abhisit.sangjan@gmail.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of tmux
#

TMUX_VERSION		= 3.5a
TMUX_TARBALL		= tmux-$(TMUX_VERSION).tar.gz
TMUX_TARBALL_URLS	+= $(ONIE_MIRROR) \
			   https://github.com/tmux/tmux/releases/download/$(TMUX_VERSION)
TMUX_BUILD_DIR		= $(USER_BUILDDIR)/tmux
TMUX_DIR		= $(TMUX_BUILD_DIR)/tmux-$(TMUX_VERSION)

TMUX_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/tmux-download
TMUX_SOURCE_STAMP	= $(USER_STAMPDIR)/tmux-source
TMUX_CONFIGURE_STAMP	= $(USER_STAMPDIR)/tmux-configure
TMUX_BUILD_STAMP	= $(USER_STAMPDIR)/tmux-build
TMUX_INSTALL_STAMP	= $(STAMPDIR)/tmux-install
TMUX_STAMP		= $(TMUX_DOWNLOAD_STAMP) \
			  $(TMUX_SOURCE_STAMP) \
			  $(TMUX_CONFIGURE_STAMP) \
			  $(TMUX_BUILD_STAMP) \
			  $(TMUX_INSTALL_STAMP)

PHONY += tmux \
	 tmux-download \
	 tmux-source \
	 tmux-configure \
	 tmux-build \
	 tmux-install \
	 tmux-clean \
	 tmux-download-clean

tmux: $(TMUX_STAMP)

DOWNLOAD += $(TMUX_DOWNLOAD_STAMP)

tmux-download: $(TMUX_DOWNLOAD_STAMP)
$(TMUX_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream tmux ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(TMUX_TARBALL) $(TMUX_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(TMUX_SOURCE_STAMP)

tmux-source: $(TMUX_SOURCE_STAMP)
$(TMUX_SOURCE_STAMP): $(USER_TREE_STAMP) | $(TMUX_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream tmux ===="
	$(Q) $(SCRIPTDIR)/extract-package $(TMUX_BUILD_DIR) $(DOWNLOADDIR)/$(TMUX_TARBALL)
	$(Q) touch $@

ifndef MAKE_CLEAN
TMUX_NEW_FILES = $( \
			shell test -d $(TMUX_DIR) && \
			test -f $(TMUX_BUILD_STAMP) && \
			find -L $(TMUX_DIR) -newer $(TMUX_BUILD_STAMP) -type f -print -quit \
		)
endif

tmux-configure: $(TMUX_CONFIGURE_STAMP)
$(TMUX_CONFIGURE_STAMP): $(TMUX_SOURCE_STAMP) $(LIBEVENT_INSTALL_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure tmux-$(TMUX_VERSION) ===="
	$(Q) cd $(TMUX_DIR) && PATH='$(CROSSBIN):$(PATH)' &&		\
		./configure						\
		--host=$(TARGET)					\
		--prefix=/usr						\
		--srcdir=$(TMUX_DIR)					\
		CFLAGS="$(ONIE_CFLAGS) -I $(DEV_SYSROOT)/usr/include"
	$(Q) touch $@

tmux-build: $(TMUX_BUILD_STAMP)
$(TMUX_BUILD_STAMP): $(TMUX_CONFIGURE_STAMP) $(TMUX_NEW_FILES) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building tmux-$(TMUX_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'					\
		$(MAKE) -C $(TMUX_DIR)					\
		CC=$(CROSSPREFIX)gcc					\
		CFLAGS="$(ONIE_CFLAGS) -I $(DEV_SYSROOT)/usr/include"
	$(Q) PATH='$(CROSSBIN):$(PATH)'
		$(MAKE) -C $(TMUX_DIR) install DESTDIR=$(DEV_SYSROOT)	\
		CC=$(CROSSPREFIX)gcc
	$(Q) touch $@

tmux-install: $(TMUX_INSTALL_STAMP)
$(TMUX_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(TMUX_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing tmux in $(SYSROOTDIR) ===="
	$(Q) mkdir -p $(SYSROOTDIR)/usr/bin/
	$(Q) cp -av $(DEV_SYSROOT)/usr/bin/tmux $(SYSROOTDIR)/usr/bin/
	$(Q) touch $@

USER_CLEAN += tmux-clean
tmux-clean:
	$(Q) rm -rf $(TMUX_BUILD_DIR)
	$(Q) rm -f $(TMUX_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += tmux-download-clean
tmux-download-clean:
	$(Q) rm -f $(TMUX_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(TMUX_TARBALL)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
