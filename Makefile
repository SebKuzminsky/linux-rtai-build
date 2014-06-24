
#
# Override these in the environment as you wish.
#

# re-enable precise when i figure out why the kernel doesnt build
#DISTS ?= wheezy precise

DISTS ?= wheezy
ARCHES ?= i386

ARCHIVE_SIGNING_KEY = 'Linux/RTAI deb archive signing key'

#
# These shouldn't be changed unless you're upgrading the packages to a new
# version of Linux or RTAI.
#

LINUX_VERSION = 3.4.87

# this is the URL of the tarball at kernel.org
LINUX_TARBALL_URL = https://www.kernel.org/pub/linux/kernel/v3.x/linux-$(LINUX_VERSION).tar.xz

LINUX_TARBALL_KERNEL_ORG = linux-$(LINUX_VERSION).tar.xz

# this is what we'll call the tarball locally, since this is the name the
# debian packaging wants
LINUX_TARBALL = linux_$(LINUX_VERSION).orig.tar.xz

LINUX_RTAI_DEBIAN_GIT = ssh://highlab.com/home/seb/linux-rtai-debian.git
LINUX_RTAI_DEBIAN_BRANCH = 3.4.87-rtai

LINUX_TOOLS_GIT = ssh://highlab.com/home/seb/linux-tools.git
LINUX_TOOLS_BRANCH = 3.4

#RTAI_GIT = https://github.com/SebKuzminsky/rtai.git
RTAI_GIT = ssh://highlab.com/home/seb/rtai.git
RTAI_BRANCH = prerelease-7


WHEEZY_KEY_ID = 6FB2A1C265FFB764
PRECISE_KEY_ID = 40976EAF437D05B5
KEY_IDS = $(WHEEZY_KEY_ID) $(PRECISE_KEY_ID)


ALL_LINUX_DSCS = $(foreach DIST,$(DISTS),stamps/$(DIST)/linux.dsc)

ALL_LINUX_DEBS = $(foreach DIST,$(DISTS),\
    $(foreach ARCH,$(ARCHES),\
        stamps/$(DIST)/$(ARCH)/linux.deb))


ALL_LINUX_TOOLS_DSCS = $(foreach DIST,$(DISTS),stamps/$(DIST)/linux-tools.dsc)

ALL_LINUX_TOOLS_DEBS = $(foreach DIST,$(DISTS),\
    $(foreach ARCH,$(ARCHES),\
        stamps/$(DIST)/$(ARCH)/linux-tools.deb))


ALL_RTAI_DSCS = $(foreach DIST,$(DISTS),stamps/$(DIST)/rtai.dsc)

ALL_RTAI_DEBS = $(foreach DIST,$(DISTS),\
    $(foreach ARCH,$(ARCHES),\
        stamps/$(DIST)/$(ARCH)/rtai.deb))


DSC_DIR = dists/$*/main/source/
DEB_DIR = dists/$(*D)/main/binary-$(*F)/
UDEB_DIR = dists/$(*D)/main/udeb/binary-$(*F)/


#
# Linux rules
#

.PHONY: linux.deb
linux.deb: $(ALL_LINUX_DEBS)

stamps/%/linux.deb: linux.dsc pbuilder/%/base.tgz
	mkdir -p pbuilder/$(*D)/$(*F)/pkgs
	sudo \
	    DIST=$(*D) \
	    ARCH=$(*F) \
	    TOPDIR=$(shell pwd) \
	    DEB_BUILD_OPTIONS=parallel=$$(($$(nproc)*3/2)) \
	    pbuilder \
	        --build \
	        --configfile pbuilderrc \
	        --basetgz pbuilder/$(*D)/$(*F)/base.tgz \
	        linux/linux_*.dsc

	# move built files to the deb archive
	install -d --mode 0755 $(UDEB_DIR)
	install -d --mode 0755 $(DEB_DIR)
	mv pbuilder/$(*D)/$(*F)/pkgs/*.udeb $(UDEB_DIR)
	mv pbuilder/$(*D)/$(*F)/pkgs/*.deb $(DEB_DIR)

	# update the deb archive
	rm -f $$(find dists/$(*D)/ -name 'Contents*')
	rm -f dists/$(*D)/Release
	rm -f dists/$(*D)/Release.gpg
	apt-ftparchive generate generate-$(*D).conf
	apt-ftparchive -c release-$(*D).conf release dists/$(*D)/ > dists/$(*D)/Release
	gpg --sign --default-key=$(ARCHIVE_SIGNING_KEY) -ba -o dists/$(*D)/Release.gpg dists/$(*D)/Release

	mkdir -p $(shell dirname $@)
	touch $@


.PHONY: linux.dsc
linux.dsc: $(ALL_LINUX_DSCS)

stamps/%/linux.dsc: stamps/linux.dsc
	install --mode 0755 --directory $(DSC_DIR)
	install --mode 0644 linux/linux_$(LINUX_VERSION)*.debian.tar.xz   $(DSC_DIR)
	install --mode 0644 linux/linux_$(LINUX_VERSION)*.dsc             $(DSC_DIR)
	install --mode 0644 linux/linux_$(LINUX_VERSION)*_source.changes  $(DSC_DIR)
	install --mode 0644 linux/linux_$(LINUX_VERSION)*.orig.tar.xz     $(DSC_DIR)
	mkdir -p $(shell dirname $@)
	touch $@

# Prepare the linux sources and the debian packaging, then make the dsc.
# FIXME: This emits an ugly error message, basically warning us
# that this is not an official Debian linux kernel package.
stamps/linux.dsc: linux/linux-$(LINUX_VERSION)
	cp linux/orig/$(LINUX_TARBALL) linux/
	( \
		cd $^; \
		fakeroot debian/rules source || true; \
		dpkg-buildpackage -S -us -uc -I; \
	)

	install --mode 0755 --directory $(shell dirname $@)
	touch $@

linux/linux-$(LINUX_VERSION): linux/orig/$(LINUX_TARBALL)
	rm -rf linux/linux-$(LINUX_VERSION)
	mkdir -p linux/linux-$(LINUX_VERSION)
	git clone $(LINUX_RTAI_DEBIAN_GIT) linux/linux-$(LINUX_VERSION)/debian
	(cd linux/linux-$(LINUX_VERSION)/debian; git checkout $(LINUX_RTAI_DEBIAN_BRANCH))
	(cd $@; fakeroot debian/rules orig)

linux/orig/$(LINUX_TARBALL_KERNEL_ORG):
	mkdir -p $(shell dirname $@)
	(cd $(shell dirname $@); curl -O $(LINUX_TARBALL_URL))

linux/orig/$(LINUX_TARBALL): linux/orig/$(LINUX_TARBALL_KERNEL_ORG)
	(cd $(shell dirname $@); cp $(LINUX_TARBALL_KERNEL_ORG) $(LINUX_TARBALL))

# this removes everything but the upstream tarball
.PHONY: clean-kernel
clean-kernel:
	rm -rf linux/linux-$(LINUX_VERSION)
	rm -f linux/linux_$(LINUX_VERSION)*
	rm -f $(ALL_LINUX_DSCS) stamps/linux.dsc


#
# linux-tools
#

.PHONY: linux-tools.deb
linux-tools.deb: $(ALL_LINUX_TOOLS_DEBS)

stamps/%/linux-tools.deb: linux-tools.dsc pbuilder/%/base.tgz
	mkdir -p pbuilder/$(*D)/$(*F)/pkgs
	sudo \
	    DIST=$(*D) \
	    ARCH=$(*F) \
	    TOPDIR=$(shell pwd) \
	    DEB_BUILD_OPTIONS=parallel=$$(($$(nproc)*3/2)) \
	    pbuilder \
	        --build \
	        --configfile pbuilderrc \
	        --basetgz pbuilder/$(*D)/$(*F)/base.tgz \
	        linux-tools/linux-tools_*.dsc

	# move built files to the deb archive
	install -d --mode 0755 $(DEB_DIR)
	mv pbuilder/$(*D)/$(*F)/pkgs/*.deb $(DEB_DIR)

	# update the deb archive
	rm -f $$(find dists/$(*D)/ -name 'Contents*')
	rm -f dists/$(*D)/Release
	rm -f dists/$(*D)/Release.gpg
	apt-ftparchive generate generate-$(*D).conf
	apt-ftparchive -c release-$(*D).conf release dists/$(*D)/ > dists/$(*D)/Release
	gpg --sign --default-key=$(ARCHIVE_SIGNING_KEY) -ba -o dists/$(*D)/Release.gpg dists/$(*D)/Release
	mkdir -p $(shell dirname $@)
	touch $@


.PHONY: linux-tools.dsc
linux-tools.dsc: $(ALL_LINUX_TOOLS_DSCS)

stamps/%/linux-tools.dsc: stamps/linux-tools.dsc
	install --mode 0755 --directory $(DSC_DIR)
	install --mode 0644 linux-tools/linux-tools_3.4-linuxcnc2.debian.tar.xz  $(DSC_DIR)
	install --mode 0644 linux-tools/linux-tools_3.4-linuxcnc2.dsc            $(DSC_DIR)
	install --mode 0644 linux-tools/linux-tools_3.4-linuxcnc2_source.changes $(DSC_DIR)
	install --mode 0644 linux-tools/linux-tools_3.4.orig.tar.xz              $(DSC_DIR)
	mkdir -p $(shell dirname $@)
	touch $@

# The "./debian/rules debian/control" step will fail; read output
stamps/linux-tools.dsc: linux-tools/linux-tools/debian/rules linux/orig/$(LINUX_TARBALL_KERNEL_ORG)
	( \
		cd linux-tools/linux-tools; \
		./debian/bin/genorig.py ../../linux/orig/$(LINUX_TARBALL_KERNEL_ORG); \
		./debian/rules debian/control; \
		./debian/rules orig; \
		./debian/rules clean; \
		dpkg-buildpackage -S -us -uc -I; \
	)
	mkdir -p $(shell dirname $@)
	touch $@

linux-tools/linux-tools/debian/rules: linux/orig/$(LINUX_TARBALL_KERNEL_ORG)
	install -d --mode 0755 linux-tools/linux-tools
	(cd linux-tools/linux-tools; git clone $(LINUX_TOOLS_GIT) debian)
	(cd linux-tools/linux-tools/debian; git checkout $(LINUX_TOOLS_BRANCH))


#
# rtai
#

.PHONY: rtai.deb
rtai.deb: $(ALL_RTAI_DEBS)

stamps/%/rtai.deb: rtai.dsc pbuilder/%/base.tgz
	mkdir -p pbuilder/$(*D)/$(*F)/pkgs
	sudo \
	    DIST=$(*D) \
	    ARCH=$(*F) \
	    TOPDIR=$(shell pwd) \
	    DEB_BUILD_OPTIONS=parallel=$$(($$(nproc)*3/2)) \
	    pbuilder \
	        --build \
	        --configfile pbuilderrc \
	        --basetgz pbuilder/$(*D)/$(*F)/base.tgz \
	        rtai_*.dsc

	# move built files to the deb archive
	install -d --mode 0755 $(DEB_DIR)
	mv pbuilder/$(*D)/$(*F)/pkgs/*.deb $(DEB_DIR)

	# update the deb archive
	rm -f $$(find dists/$(*D)/ -name 'Contents*')
	rm -f dists/$(*D)/Release
	rm -f dists/$(*D)/Release.gpg
	apt-ftparchive generate generate-$(*D).conf
	apt-ftparchive -c release-$(*D).conf release dists/$(*D)/ > dists/$(*D)/Release
	gpg --sign --default-key=$(ARCHIVE_SIGNING_KEY) -ba -o dists/$(*D)/Release.gpg dists/$(*D)/Release
	mkdir -p $(shell dirname $@)
	touch $@

.PHONY: rtai.dsc
rtai.dsc: $(ALL_RTAI_DSCS)

stamps/%/rtai.dsc: stamps/rtai.dsc
	install --mode 0755 --directory $(DSC_DIR)
	install --mode 0644 rtai_*.tar.gz         $(DSC_DIR)
	install --mode 0644 rtai_*.dsc            $(DSC_DIR)
	install --mode 0644 rtai_*_source.changes $(DSC_DIR)
	mkdir -p $(shell dirname $@)
	touch $@

stamps/rtai.dsc: rtai/debian/rules
	( \
		cd rtai; \
		./autogen.sh; \
		dpkg-buildpackage -S -us -uc -I; \
	)
	mkdir -p $(shell dirname $@)
	touch $@

rtai/debian/rules:
	git clone $(RTAI_GIT) rtai
	(cd rtai; git checkout $(RTAI_BRANCH))


#
# pbuilder rules
#

# Base chroot tarballs are named e.g. pbuilder/lucid/i386/base.tgz
# in this case, $(*D) = lucid; $(*F) = i386
pbuilder/%/base.tgz: pbuilder/keyring.gpg
	mkdir -p pbuilder/$(*D)/$(*F)
	sudo DIST=$(*D) ARCH=$(*F) TOPDIR=$(shell pwd) pbuilder --create --basetgz $@ --configfile pbuilderrc

pbuilder/keyring.gpg:
	mkdir -p pbuilder
	gpg --keyserver hkp://keys.gnupg.net --keyring $@ --no-default-keyring --recv-key $(KEY_IDS)

.PHONY: clean-pbuilder
clean-pbuilder:
	rm -rf pbuilder/


#
# misc rules
#

.PHONY: clean
clean: clean-pbuilder
	rm -rf linux/
	rm -rf aptcache/
	# git clean -fdx .

