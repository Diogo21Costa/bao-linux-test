# Build Instructions


## 0. Setup environment

```sh
export ARCH=aarch64
export PLAFORM=qemu-aarch64-virt
export ROOT_DIR=$(realpath .)
export WRKDIR=$ROOT_DIR/wrkdir

export BUILDROOT_ARCH=arm64

export LINUX_REPO=https://github.com/torvalds/linux.git
export LINUX_VERSION=v6.1
export LINUX_SRC=$WRKDIR/linux-$LINUX_VERSION

export BUILDROOT_REPO=https://github.com/buildroot/buildroot.git
export BUILDROOT_VERSION=2022.11
export BUILDROOT_SRC=$WRKDIR/buildroot-$ARCH-$BUILDROOT_VERSION

mkdir -p $ROOT_DIR/wrkdir
```

## 1. Download Buildroot and create rootfs
```sh
export BAO_BUILDROOT_DEFCFG=$ROOT_DIR/buildroot/$ARCH.config
git clone $BUILDROOT_REPO $BUILDROOT_SRC\
    --depth 1 --branch $BUILDROOT_VERSION

cd $BUILDROOT_SRC
make defconfig BR2_DEFCONFIG=$BAO_BUILDROOT_DEFCFG

make
```

## 2. Download the Linux kernel source


```sh
git clone $LINUX_REPO $LINUX_SRC\
    --depth 1 --branch $LINUX_VERSION
cd $LINUX_SRC
git am $ROOT_DIR/patches/$LINUX_VERSION/*.patch

export LINUX_SRC_CFG_FRAG=$(ls $ROOT_DIR/configs/base.config\
    $ROOT_DIR/configs/$ARCH.config\
    $ROOT_DIR/configs/$PLATFORM.config 2> /dev/null)

make defconfig ARCH=$BUILDROOT_ARCH CROSS_COMPILE=$BUILDROOT_SRC/output/host/bin/$ARCH-linux-
make ARCH=$BUILDROOT_ARCH CROSS_COMPILE=$BUILDROOT_SRC/output/host/bin/$ARCH-linux- -j$(nproc) Image
cp $LINUX_SRC/arch/$BUILDROOT_ARCH/boot/Image $WRKDIR/Image-$PLATFORM
```

## 3. compile Linux's device tree and static guest loader (to run over Bao)

Compile device tree:

```sh
dtc $ROOT_DIR/devicetrees/$PLATFORM/linux.dts -o $WRKDIR/linux.dtb
```

Compile static guest loader:
```sh
make -C $ROOT_DIR/bao-static-guest-loader\
    ARCH=$ARCH\
    IMAGE=$WRKDIR/Image-$PLATFORM\
    DTB=$WRKDIR/linux.dtb\
    TARGET=$WRKDIR/linux\
    INITRAMFS=$WRKDIR/rootfs.cpio
```