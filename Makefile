
#
# Override these in the environment as you wish.
#

DIST ?= wheezy
ARCH ?= i386


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


#
# Linux rules
#

.PHONY: linux.deb
linux.deb: linux.dsc

.PHONY: linux.dsc
linux.dsc: linux/linux-$(LINUX_VERSION)
	# Prepare the linux sources and the debian packaging, then make the dsc.
	# FIXME: This emits an ugly error message, basically warning us
	# that this is not an official Debian linux kernel package.
	( \
		cd $^; \
		fakeroot debian/rules source || true; \
		dpkg-buildpackage -S -us -uc -I; \
	)

linux/linux-$(LINUX_VERSION): linux/linux-$(LINUX_VERSION)/debian
	(cd $@; fakeroot debian/rules orig)

linux/linux-$(LINUX_VERSION)/debian: linux/$(LINUX_TARBALL)
	mkdir linux/linux-$(LINUX_VERSION)
	git clone $(LINUX_RTAI_DEBIAN_GIT) linux/linux-$(LINUX_VERSION)/debian
	(cd linux/linux-$(LINUX_VERSION)/debian; git checkout $(LINUX_RTAI_DEBIAN_BRANCH))

#linux/linux-$(LINUX_VERSION): linux/$(LINUX_TARBALL)
#	(cd linux; tar --xz -xf $(LINUX_TARBALL))

linux/$(LINUX_TARBALL):
	mkdir -p linux
	curl -o $@ $(LINUX_TARBALL_URL)

.PHONY: clean-kernel
clean-kernel:
	rm -rf linux/linux-$(LINUX_VERSION)


#
# misc rules
#

.PHONY: clean
clean:
	rm -rf linux/

