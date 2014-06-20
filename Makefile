
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
LINUX_TARBALL = linux-$(LINUX_VERSION).tar.gz
LINUX_TARBALL_URL = https://www.kernel.org/pub/linux/kernel/v3.x/$(LINUX_TARBALL)

LINUX_RTAI_DEBIAN_GIT = ssh://highlab.com/home/seb/linux-rtai-debian.git
LINUX_RTAI_DEBIAN_BRANCH = 3.4.87-rtai


#
# rules
#

.PHONY: linux.dsc
linux.dsc: linux/linux-$(LINUX_VERSION) linux/linux-$(LINUX_VERSION)/debian

linux/linux-$(LINUX_VERSION)/debian: linux/linux-$(LINUX_VERSION)
	( \
		set -e; \
		cd linux/linux-$(LINUX_VERSION); \
		git clone $(LINUX_RTAI_DEBIAN_GIT) debian; \
		cd debian; \
		git checkout $(LINUX_RTAI_DEBIAN_BRANCH); \
        )

linux/linux-$(LINUX_VERSION): linux/$(LINUX_TARBALL)
	(cd linux; tar -xzf $(LINUX_TARBALL))

linux/$(LINUX_TARBALL):
	mkdir -p linux
	curl -o $@ $(LINUX_TARBALL_URL)

.PHONY: clean-kernel
clean-kernel:
	rm -rf linux/linux-$(LINUX_VERSION)

.PHONY: clean
clean:
	rm -rf linux/

