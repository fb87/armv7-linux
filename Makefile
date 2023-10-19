OBJ_DIR       ?= /tmp/opi0-build
BIN_DIR       ?= ${shell pwd}/bin
SRC_DIR       ?= ${shell pwd}/src

JOBS          ?= 8 # more jobs might cause error due to resource limiting

PRE_BUILD     ?= mkdir -p ${OBJ_DIR} ${BIN_DIR}
BUILD_CMD     ?= ${PRE_BUILD} && podman run --rm -it \
                -v ${OBJ_DIR}:/obj_dir \
                -v ${SRC_DIR}:/src_dir \
                -v ${BIN_DIR}:/bin_dir \
                armhf-builder
MAKE_FLAGS    ?= ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- 
MAKE_CMD      := ${BUILD_CMD} make ${MAKE_FLAGS} -j${JOBS}
BASH_CMD      := ${BUILD_CMD} /bin/bash -c


all: builder bootable
	@echo "---Output artifact ${BIN_DIR}---"
	@ls -al ${BIN_DIR}

builder:
	podman build -t armhf-builder .

bootable: linux initrd.cpio.gz.uboot boot.scr

src/linux.tar.gz:
	@curl -L -o $@ https://github.com/torvalds/linux/archive/refs/tags/v6.5.tar.gz
	@mkdir -p src/linux
	@tar -C src/linux -xf $@ --strip-component=1

src/u-boot.tar.gz:
	@curl -L -o $@ https://github.com/u-boot/u-boot/archive/refs/tags/v2023.10.tar.gz
	@mkdir -p src/u-boot
	@tar -C src/u-boot -xf $@ --strip-component=1

src/busybox.tar.gz:
	@curl -L -o $@ https://github.com/mirror/busybox/archive/refs/tags/1_36_0.tar.gz
	@mkdir -p src/busybox
	@tar -C src/busybox -xf $@ --strip-component=1

u-boot: src/u-boot.tar.gz
	@mkdir -p ${OBJ_DIR}/$@
	# build u-boot images
	@${MAKE_CMD} -C /src_dir/$@ orangepi_zero_defconfig all -j$(nproc)
	# sync images to output folder
	@${BASH_CMD} "cp -f /src_dir/$@/.config /obj_dir/$@"
	@${BASH_CMD} "cp -f /src_dir/$@/*.bin 	/bin_dir/"

linux: src/linux.tar.gz
	@mkdir -p ${OBJ_DIR}/$@
	# build linux images
	@${MAKE_CMD} -C /src_dir/$@ LOADADDR=0x40008000 INSTALL_MOD_PATH=/obj_dir/$@ sunxi_defconfig uImage dtbs modules modules_install
	# sync images to output folder
	@${BASH_CMD} "cp -f /src_dir/$@/{arch/arm/boot/*Image,arch/arm/boot/dts/allwinner/sun8i-h3-orangepi-zero-plus2.dtb} /bin_dir/"
	@${BASH_CMD} "mkdir -p /obj_dir/$@ && cp -Rf /src_dir/$@/{lib,.config} /obj_dir/$@"

busybox: src/busybox.tar.gz
	# build images
	@${MAKE_CMD} -C /src_dir/$@ CONFIG_STATIC=y defconfig 
	@${MAKE_CMD} -C /src_dir/$@ CONFIG_STATIC=y install
	# sync images to output folder
	@${BASH_CMD} "mkdir -p /obj_dir/$@ && cp -Rf /src_dir/$@/_install/* /obj_dir/$@"

overlay: busybox
	@mkdir -p ${OBJ_DIR}/$</etc/init.d
	@echo -ne '#!/bin/sh\n\n' > ${OBJ_DIR}/$</etc/init.d/rcS
	@echo -ne 'mount -t proc  none /proc\nmount -t sysfs none /sys\n\nmdev -s' >> ${OBJ_DIR}/$</etc/init.d/rcS
	@chmod +x ${OBJ_DIR}/$</etc/init.d/rcS

initrd.cpio.gz.uboot: overlay linux busybox u-boot
	@mkdir -p ${OBJ_DIR}/$@
	(cd ${OBJ_DIR}/$@; rm -Rf * && mkdir -p proc dev sys usr/local/bin)
	(cd ${OBJ_DIR}/$@; cp -Rf ${OBJ_DIR}/linux/lib .)
	(cd ${OBJ_DIR}/$@; cp -Rf ${OBJ_DIR}/busybox/* .)
	(cd ${OBJ_DIR}/$@; find . | cpio --quiet -H newc -o | gzip -9 -n > ${OBJ_DIR}/initrd.cpio.gz)
	(cd ${OBJ_DIR}/$@; mkimage -A arm -O linux -T ramdisk -C gzip -d ${OBJ_DIR}/initrd.cpio.gz ${BIN_DIR}/initrd.cpio.gz.uboot)

boot.scr: ${OBJ_DIR}/u-boot
	(cd $<; echo 'setenv bootargs console=ttyS0,115200 root=/dev/ram0 rdinit=/sbin/init rootdelay=2 loglevel=7' > boot.cmd)
	(cd $<; echo setenv bootcmd bootm 0x41000000 0x41c00000 0x41800000 >> boot.cmd)
	(cd $<; echo run bootcmd >> boot.cmd)
	(cd $<; mkimage -C none -A arm -T script -d boot.cmd ${BIN_DIR}/boot.scr)

boot: boot.scr
	@sudo sunxi-fel -v uboot    ${BIN_DIR}/u-boot-sunxi-with-spl.bin \
             write 0x41000000 ${BIN_DIR}/uImage \
             write 0x41800000 ${BIN_DIR}/sun8i-h3-orangepi-zero-plus2.dtb \
             write 0x4fc00000 ${BIN_DIR}/boot.scr \
             write 0x41C00000 ${BIN_DIR}/initrd.cpio.gz.uboot

distclean: clean
	@${MAKE_CMD} -C /src_dir/linux distclean
	@${MAKE_CMD} -C /src_dir/u-boot distclean
	@${MAKE_CMD} -C /src_dir/busybox distclean

clean:
	@rm -Rf ${BIN_DIR} ${OBJ_DIR}
