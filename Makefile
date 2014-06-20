
#
# Override these in the environment as you wish.
#

DISTS ?= wheezy precise
ARCHES ?= i386


#
# These shouldn't be changed unless you're upgrading the packages to a new
# version of Linux or RTAI.
#

LINUX_VERSION = 3.4.87

# this is the URL of the tarball at kernel.org
LINUX_TARBALL_URL = https://www.kernel.org/pub/linux/kernel/v3.x/linux-$(LINUX_VERSION).tar.xz

# this is what we'll call the tarball locally, since this is the name the
# debian packaging wants
LINUX_TARBALL = linux_$(LINUX_VERSION).orig.tar.xz

LINUX_RTAI_DEBIAN_GIT = ssh://highlab.com/home/seb/linux-rtai-debian.git
LINUX_RTAI_DEBIAN_BRANCH = 3.4.87-rtai


WHEEZY_KEY_ID = 6FB2A1C265FFB764
PRECISE_KEY_ID = 40976EAF437D05B5
KEY_IDS = $(WHEEZY_KEY_ID) $(PRECISE_KEY_ID)


ALL_LINUX_DSCS = $(foreach DIST,$(DISTS),dists/$(DIST)/source/.stamp-linux.dsc)


#
# Linux rules
#

.PHONY: linux.deb
linux.deb: linux.dsc pbuilder/$(DIST)-$(ARCH).tgz

.PHONY: linux.dsc
linux.dsc: $(ALL_LINUX_DSCS)

dists/%/source/.stamp-linux.dsc: linux/.stamp-linux.dsc
	install --directory $(shell dirname $@)/
	install --mode 644 linux/linux_$(LINUX_VERSION)*.debian.tar.xz   $(shell dirname $@)/
	install --mode 644 linux/linux_$(LINUX_VERSION)*.dsc             $(shell dirname $@)/
	install --mode 644 linux/linux_$(LINUX_VERSION)*_source.changes  $(shell dirname $@)/
	install --mode 644 linux/linux_$(LINUX_VERSION)*.orig.tar.xz     $(shell dirname $@)/
	touch $@

# Prepare the linux sources and the debian packaging, then make the dsc.
# FIXME: This emits an ugly error message, basically warning us
# that this is not an official Debian linux kernel package.
linux/.stamp-linux.dsc: linux/linux-$(LINUX_VERSION)
	cp linux/orig/$(LINUX_TARBALL) linux/
	( \
		cd $^; \
		fakeroot debian/rules source || true; \
		dpkg-buildpackage -S -us -uc -I; \
	)
	touch $@

linux/linux-$(LINUX_VERSION): linux/orig/$(LINUX_TARBALL)
	rm -rf linux/linux-$(LINUX_VERSION)
	mkdir linux/linux-$(LINUX_VERSION)
	git clone $(LINUX_RTAI_DEBIAN_GIT) linux/linux-$(LINUX_VERSION)/debian
	(cd linux/linux-$(LINUX_VERSION)/debian; git checkout $(LINUX_RTAI_DEBIAN_BRANCH))
	(cd $@; fakeroot debian/rules orig)

linux/orig/$(LINUX_TARBALL):
	mkdir -p $(shell dirname $@)
	curl -o $@ $(LINUX_TARBALL_URL)

# this removes everything but the upstream tarball
.PHONY: clean-kernel
clean-kernel:
	rm -rf linux/linux-$(LINUX_VERSION)
	rm -f linux/linux_$(LINUX_VERSION)*
	rm -f linux/.stamp-linux.dsc


#
# pbuilder rules
#

# Base chroot tarballs are named e.g. pbuilder/lucid/i386/base.tgz
# in this case, $(*D) = lucid; $(*F) = i386
pbuilder/%/base.tgz: pbuilder/keyring.gpg
	mkdir -p pbuilder/$(*D)/$(*F)
	sudo DIST=$(*D) ARCH=$(*F) TOPDIR=$(shell pwd) pbuilder --create --basetgz $@ --configfile pbuilderrc


#pbuilder/$(DIST)-$(ARCH).tgz: pbuilder/keyring.gpg
# wheezy:
#	sudo pbuilder --create --basetgz $@ --mirror http://ftp.debian.org/debian --distribution wheezy --architecture i386 --components 'main' --debootstrapopts --keyring=$HOME/.gnupg/pubring.gpg
#
#    precise:
#        sudo pbuilder --create --basetgz pbuilder/precise-i386.tgz --mirror http://us.archive.ubuntu.com/ubuntu --distribution precise --architecture i386 --components 'main' --debootstrap

pbuilder/keyring.gpg:
	mkdir -p pbuilder
	gpg --keyserver hkp://keys.gnupg.net --keyring $@ --no-default-keyring --recv-key $(KEY_IDS)

.PHONY: clean-pbuilder
clean-pbuilder:
	sudo rm -rf pbuilder/aptcache
	rm -rf pbuilder/


#
# misc rules
#

.PHONY: clean
clean: clean-pbuilder
	rm -rf linux/
	rm -rf aptcache/
	# git clean -fdx .

