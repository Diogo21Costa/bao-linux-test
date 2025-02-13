ROOT_DIR := $(shell realpath .)
WRKDIR := $(ROOT_DIR)/wrkdir

BUILDROOT_VERSION := 2022.11
BUILDROOT_REPO := https://github.com/buildroot/buildroot.git

ifndef PLATFORM
  $(error PLATFORM not defined)
endif

ifndef ARCH
  $(error ARCH not defined)
endif

PLATFORMS_AARCH64 := qemu-aarch64-virt fvp-a fvp-r zcu102 zcu104 imx8qm tx2 rpi4
PLATFORMS_RISCV64 := qemu-riscv64-virt

ifeq ($(filter $(PLATFORM), $(PLATFORMS_AARCH64)), $(PLATFORM))
  BUILDROOT_ARCH := arm64
  LINUX_REPO := https://github.com/torvalds/linux.git
  LINUX_VERSION := v6.1

  ifeq ($(PLATFORM), imx8qm)
    LINUX_REPO := https://source.codeaurora.org/external/imx/linux-imx
    LINUX_VERSION := rel_imx_5.4.24_2.1.0
  endif

else ifeq ($(filter $(PLATFORM), $(PLATFORMS_RISCV64)), $(PLATFORM))
  BUILDROOT_ARCH := riscv
  LINUX_REPO := https://github.com/torvalds/linux.git
  LINUX_VERSION := v6.1

else
  $(error Unsupported PLATFORM: $(PLATFORM))
endif

BUILDROOT_SRC := $(WRKDIR)/buildroot-$(ARCH)-$(BUILDROOT_VERSION)
LINUX_SRC := $(WRKDIR)/linux-$(PLATFORM)
BAO_BUILDROOT_DEFCFG := $(ROOT_DIR)/buildroot/$(ARCH).config

ifeq ("$(wildcard $(BAO_BUILDROOT_DEFCFG))","")
  $(error BAO_BUILDROOT_DEFCFG file not found: $(BAO_BUILDROOT_DEFCFG))
endif

.PHONY: all setup buildroot linux clean

all: buildroot linux

setup:
	mkdir -p $(WRKDIR)

buildroot: setup
	if [ ! -d "$(BUILDROOT_SRC)" ]; then \
		echo "Cloning Buildroot repository..."; \
		git clone $(BUILDROOT_REPO) $(BUILDROOT_SRC) --depth 1 --branch $(BUILDROOT_VERSION); \
	else \
		echo "Buildroot repository already exists, skipping clone."; \
	fi

	cd $(BUILDROOT_SRC) && \
	make clean
	cd $(BUILDROOT_SRC) && \
	make defconfig BR2_DEFCONFIG=$(BAO_BUILDROOT_DEFCFG) && \
	make
	cp $(BUILDROOT_SRC)/output/images/rootfs.cpio $(WRKDIR)/rootfs_$(PLATFORM).cpio

linux: setup
	if [ ! -d "$(LINUX_SRC)" ]; then \
		echo "Cloning Linux repository..."; \
		git clone $(LINUX_REPO) $(LINUX_SRC) --depth 1 --branch $(LINUX_VERSION); \
	else \
		echo "Linux repository already exists, skipping clone."; \
	fi

	cd $(LINUX_SRC) && \
	if [ -d $(ROOT_DIR)/patches/$(LINUX_VERSION) ]; then \
	  git apply $(ROOT_DIR)/patches/$(LINUX_VERSION)/*.patch; \
	fi

	cd $(LINUX_SRC) && \
	make clean ARCH=$(BUILDROOT_ARCH) && \
	make defconfig ARCH=$(BUILDROOT_ARCH) CROSS_COMPILE=$(BUILDROOT_SRC)/output/host/bin/$(ARCH)-linux- && \
	make ARCH=$(BUILDROOT_ARCH) CROSS_COMPILE=$(BUILDROOT_SRC)/output/host/bin/$(ARCH)-linux- -j$$(nproc) Image
	cp $(LINUX_SRC)/arch/$(BUILDROOT_ARCH)/boot/Image $(WRKDIR)/Image-$(PLATFORM)

clean:
	rm -rf $(WRKDIR)
