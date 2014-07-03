
#
# Override these in the environment as you wish.
#

DISTS ?= wheezy precise
ARCHES ?= i386

LINUX_IMAGE_VERSION ?= 3.4-9-rtai-686-pae

ARCHIVE_SIGNING_KEY = 'Linux/RTAI deb archive signing key'

#
# These shouldn't be changed unless you're upgrading the packages to a new
# version of Linux or RTAI.
#


#
# kernel-wedge, needed by Precise to build the debian.org packaging of the
# linux kernel
#

KERNEL_WEDGE_GIT = git://git.debian.org/d-i/kernel-wedge.git
KERNEL_WEDGE_BRANCH = 2.84

ALL_KERNEL_WEDGE_DSCS = $(foreach DIST,precise,stamps/$(DIST)/kernel-wedge.dsc)

ALL_KERNEL_WEDGE_DEBS = $(foreach DIST,precise,\
    $(foreach ARCH,$(ARCHES),\
        stamps/$(DIST)/$(ARCH)/kernel-wedge.deb))


#
# kmod, replaces module-init-tools, needed by Precise to build the
# debian.org packaging of the linux kernel
#

KMOD_GIT = git://git.kernel.org/pub/scm/utils/kernel/kmod/kmod.git
KMOD_BRANCH = v9

ALL_KMOD_DSCS = $(foreach DIST,precise,stamps/$(DIST)/kmod.dsc)

ALL_KMOD_DEBS = $(foreach DIST,precise,\
    $(foreach ARCH,$(ARCHES),\
        stamps/$(DIST)/$(ARCH)/kmod.deb))


#
# linux
#

LINUX_VERSION = 3.4.87

# this is the URL of the tarball at kernel.org
LINUX_TARBALL_URL = https://www.kernel.org/pub/linux/kernel/v3.x/linux-$(LINUX_VERSION).tar.xz

LINUX_TARBALL_KERNEL_ORG = linux-$(LINUX_VERSION).tar.xz

# this is what we'll call the tarball locally, since this is the name the
# debian packaging wants
LINUX_TARBALL = linux_$(LINUX_VERSION).orig.tar.xz


#
# this is the linux/debian directory for the rtai-patched kernel
#

LINUX_RTAI_DEBIAN_GIT = ssh://highlab.com/home/seb/linux-rtai-debian.git
LINUX_RTAI_DEBIAN_BRANCH = 3.4.87-rtai


#
# linux-tools
# a specific version of the debian.org upstream, with minor tweaks
#

LINUX_TOOLS_GIT = ssh://highlab.com/home/seb/linux-tools.git
LINUX_TOOLS_BRANCH = 3.4


#
# rtai
#

# ShabbyX RTAI fork, my branch adds debian packaging
#RTAI_GIT = https://github.com/SebKuzminsky/rtai.git
RTAI_GIT = ssh://highlab.com/home/seb/rtai.git

RTAI_BRANCH = deb-packaging


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


DSC_DIR = dists/$(*D)/main/source/
DEB_DIR = dists/$(*D)/main/binary-$(*F)/
UDEB_DIR = dists/$(*D)/main/udeb/binary-$(*F)/


#
# kernel-wedge rules
#

.PHONY: kernel-wedge.deb
kernel-wedge.deb: $(ALL_KERNEL_WEDGE_DEBS)

stamps/%/kernel-wedge.deb: kernel-wedge.dsc pbuilder/%/base.tgz
	mkdir -p pbuilder/$(*D)/$(*F)/pkgs
	sudo \
	    DIST=$(*D) \
	    ARCH=$(*F) \
	    TOPDIR=$(shell pwd) \
	    DEB_BUILD_OPTIONS=parallel=$$(($$(nproc)*3/2)) \
	    pbuilder \
	        --build \
	        --configfile pbuilderrc \
	        kernel-wedge/kernel-wedge*.dsc

	# move built files to the deb archive
	install -d --mode 0755 $(DEB_DIR)
	mv pbuilder/$(*D)/$(*F)/pkgs/*.deb $(DEB_DIR)

	./update-deb-archive $(ARCHIVE_SIGNING_KEY) $(*D) $(*F)

	mkdir -p $(shell dirname $@)
	touch $@


.PHONY: kernel-wedge.dsc
kernel-wedge.dsc: $(ALL_KERNEL_WEDGE_DSCS)

stamps/%/kernel-wedge.dsc: stamps/kernel-wedge.dsc
	install --mode 0755 --directory $(DSC_DIR)
	install --mode 0644 kernel-wedge/kernel-wedge_*.dsc            $(DSC_DIR)
	install --mode 0644 kernel-wedge/kernel-wedge_*_source.changes $(DSC_DIR)
	install --mode 0644 kernel-wedge/kernel-wedge_*.tar.gz         $(DSC_DIR)
	mkdir -p $(shell dirname $@)
	touch $@

stamps/kernel-wedge.dsc: kernel-wedge/kernel-wedge
	( \
		cd $^; \
		dpkg-buildpackage -S -us -uc -I; \
	)

	install --mode 0755 --directory $(shell dirname $@)
	touch $@

kernel-wedge/kernel-wedge:
	mkdir -p kernel-wedge
	cd kernel-wedge; git clone $(KERNEL_WEDGE_GIT)
	cd kernel-wedge/kernel-wedge; git checkout $(KERNEL_WEDGE_BRANCH)

clean-kernel-wedge:
	rm -rf kernel-wedge




#
# kmod rules
#

.PHONY: kmod.deb
kmod.deb: $(ALL_KMOD_DEBS)

stamps/%/kmod.deb: kmod.dsc pbuilder/%/base.tgz
	mkdir -p pbuilder/$(*D)/$(*F)/pkgs
	sudo \
	    DIST=$(*D) \
	    ARCH=$(*F) \
	    TOPDIR=$(shell pwd) \
	    DEB_BUILD_OPTIONS=parallel=$$(($$(nproc)*3/2)) \
	    pbuilder \
	        --build \
	        --configfile pbuilderrc \
	        kmod/kmod_*.dsc

	# move built files to the deb archive
	install -d --mode 0755 $(DEB_DIR)
	mv pbuilder/$(*D)/$(*F)/pkgs/*.deb $(DEB_DIR)

	./update-deb-archive $(ARCHIVE_SIGNING_KEY) $(*D) $(*F)

	mkdir -p $(shell dirname $@)
	touch $@


.PHONY: kmod.dsc
kmod.dsc: $(ALL_KMOD_DSCS)

stamps/%/kmod.dsc: stamps/kmod.dsc
	install --mode 0755 --directory $(DSC_DIR)
	install --mode 0644 kmod/kmod_*.dsc            $(DSC_DIR)
	install --mode 0644 kmod/kmod_*.debian.tar.gz  $(DSC_DIR)
	install --mode 0644 kmod/kmod_*.orig.tar.xz    $(DSC_DIR)
	mkdir -p $(shell dirname $@)
	touch $@

stamps/kmod.dsc: kmod/kmod
	( \
		cd $^; \
		dpkg-buildpackage -S -us -uc -I; \
	)

	install --mode 0755 --directory $(shell dirname $@)
	touch $@

kmod/kmod:
	mkdir -p kmod
	cd kmod; git clone $(KMOD_GIT)
	cd kmod/kmod; git checkout $(KMOD_BRANCH)

clean-kmod:
	rm -rf kmod


#
# Linux rules
#

.PHONY: linux.deb
linux.deb: $(ALL_LINUX_DEBS)

# FIXME: if there are multiple linux.dsc versions, the wildcard argument
#     to pbuilder will do the wrong thing
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
	        linux/linux_*.dsc
	
	# move built files to the deb archive
	install -d --mode 0755 $(UDEB_DIR)
	install -d --mode 0755 $(DEB_DIR)
	mv pbuilder/$(*D)/$(*F)/pkgs/*.udeb $(UDEB_DIR)
	mv pbuilder/$(*D)/$(*F)/pkgs/*.deb $(DEB_DIR)
	
	./update-deb-archive $(ARCHIVE_SIGNING_KEY) $(*D) $(*F)
	
	mkdir -p $(shell dirname $@)
	touch $@


.PHONY: linux.dsc
linux.dsc: clean-linux-dsc $(ALL_LINUX_DSCS)

stamps/%/linux.dsc: stamps/linux.dsc.build
	install --mode 0755 --directory $(DSC_DIR)
	install --mode 0644 linux/linux_*.debian.tar.xz   $(DSC_DIR)
	install --mode 0644 linux/linux_*.dsc             $(DSC_DIR)
	install --mode 0644 linux/linux_*_source.changes  $(DSC_DIR)
	install --mode 0644 linux/linux_*.orig.tar.xz     $(DSC_DIR)
	mkdir -p $(shell dirname $@)
	touch $@

# Prepare the linux sources and the debian packaging, then make the dsc.
# FIXME: This emits an ugly error message, basically warning us
# that this is not an official Debian linux kernel package.
stamps/linux.dsc.build: linux/linux-$(LINUX_VERSION)
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
	rm -f $(ALL_LINUX_DSCS) stamps/linux.dsc.build


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
	        linux-tools/linux-tools_*.dsc

	# move built files to the deb archive
	install -d --mode 0755 $(DEB_DIR)
	mv pbuilder/$(*D)/$(*F)/pkgs/*.deb $(DEB_DIR)

	./update-deb-archive $(ARCHIVE_SIGNING_KEY) $(*D) $(*F)

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

stamps/%/rtai.deb: stamps/%/rtai.dsc pbuilder/%/base.tgz
	mkdir -p pbuilder/$(*D)/$(*F)/pkgs
	sudo \
	    DIST=$(*D) \
	    ARCH=$(*F) \
	    TOPDIR=$(shell pwd) \
	    DEB_BUILD_OPTIONS=parallel=$$(($$(nproc)*3/2)) \
	    pbuilder \
	        --build \
	        --configfile pbuilderrc \
	        dists/$(*D)/main/source/rtai_*.dsc

	# move built files to the deb archive
	install -d --mode 0755 $(DEB_DIR)
	mv pbuilder/$(*D)/$(*F)/pkgs/*.deb $(DEB_DIR)

	./update-deb-archive $(ARCHIVE_SIGNING_KEY) $(*D) $(*F)

	mkdir -p $(shell dirname $@)
	touch $@

.PHONY: rtai.dsc
rtai.dsc: $(ALL_RTAI_DSCS)

stamps/%/rtai.dsc: stamps/rtai.dsc
	install --mode 0755 --directory $(DSC_DIR)
	rm -f $(DSC_DIR)/rtai_*.tar.gz
	rm -f $(DSC_DIR)/rtai_*.dsc
	rm -f $(DSC_DIR)/rtai_*_source.changes
	install --mode 0644 rtai_*.tar.gz         $(DSC_DIR)
	install --mode 0644 rtai_*.dsc            $(DSC_DIR)
	install --mode 0644 rtai_*_source.changes $(DSC_DIR)
	mkdir -p $(shell dirname $@)
	touch $@

stamps/rtai.dsc: rtai/debian/rules.in
	rm -f rtai_*.tar.gz
	rm -f rtai_*.dsc
	rm -f rtai_*_source.changes
	( \
		cd rtai; \
		debian/configure $(LINUX_IMAGE_VERSION); \
		debian/update-dch-from-git; \
		./autogen.sh; \
		dpkg-buildpackage -S -us -uc -I; \
	)
	mkdir -p $(shell dirname $@)
	touch $@

rtai/debian/rules.in:
	git clone $(RTAI_GIT) rtai
	(cd rtai; git checkout $(RTAI_BRANCH))


#
# pbuilder rules
#

# Base chroot tarballs are named e.g. pbuilder/lucid/i386/base.tgz
# in this case, $(*D) = lucid; $(*F) = i386
# FIXME: probably need to create an empty dist hierarchy first
.PHONY: pbuilder/%/base.tgz
pbuilder/%/base.tgz: pbuilder/keyring.gpg stamps/%/deb-archive
	if [ -f pbuilder/$(*D)/$(*F)/base.tgz ]; then \
		sudo DIST=$(*D) ARCH=$(*F) TOPDIR=$(shell pwd) pbuilder --update --configfile pbuilderrc; \
	else \
		mkdir -p pbuilder/$(*D)/$(*F); \
		sudo DIST=$(*D) ARCH=$(*F) TOPDIR=$(shell pwd) pbuilder --create --configfile pbuilderrc; \
	fi

pbuilder/keyring.gpg:
	mkdir -p pbuilder
	gpg --keyserver hkp://keys.gnupg.net --keyring $@ --no-default-keyring --recv-key $(KEY_IDS)
	gpg --armor --export $(ARCHIVE_SIGNING_KEY) | gpg --keyring pbuilder/keyring.gpg --no-default-keyring --import --armor
	mkdir -p dists
	gpg --armor --export $(ARCHIVE_SIGNING_KEY) >| dists/archive-signing-key.gpg

.PHONY: clean-pbuilder
clean-pbuilder:
	rm -rf pbuilder/


#
# misc rules
#

stamps/%/deb-archive:
	mkdir -p dists/$(*D)/main/source
	mkdir -p dists/$(*D)/main/binary-$(*F)/
	./update-deb-archive $(ARCHIVE_SIGNING_KEY) $(*D) $(*F)

.PHONY: clean-%-dsc
clean-%-dsc:
	rm -f $*/$*_*.debian.tar.xz
	rm -f $*/$*_*.dsc
	rm -f $*/$*_*_source.changes
	rm -f $*/$*_*.orig.tar.xz
	rm -f stamps/$*.dsc.build

.PHONY: clean
clean:
	rm -rf linux/
	rm -rf linux-tools/
	rm -rf rtai/
	rm -rf dists/
	rm -rf pbuilder/*/*/pkgs/
	rm -rf stamps/

.PHONY: super-clean
super-clean: clean
	sudo rm -rf aptcache/
	sudo rm -rf ccache/

