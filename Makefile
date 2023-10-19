OBJ_DIR       ?= /tmp/opi0-build

all: prepare ${OBJ_DIR}/alpine-uboot-3.18.4-armv7.tar.gz ${OBJ_DIR}/boot.scr ${OBJ_DIR}/initrd.cpio.gz.uboot 
	@echo "---Output artifact ${OBJ_DIR}---"
	@ls -al ${OBJ_DIR}

prepare:
	@mkdir -p ${OBJ_DIR}

${OBJ_DIR}/alpine-uboot-3.18.4-armv7.tar.gz:
	@curl -L -o $@ https://dl-cdn.alpinelinux.org/alpine/v3.18/releases/armv7/alpine-uboot-3.18.4-armv7.tar.gz
	@mkdir -p ${OBJ_DIR}/alpine-rootfs
	@tar -C ${OBJ_DIR}/alpine-rootfs -xf $@

${OBJ_DIR}/initrd.cpio.gz.uboot: ${OBJ_DIR}/alpine-rootfs
	(cd ${OBJ_DIR}/$<; find . | cpio --quiet -H newc -o | gzip -9 -n > ${OBJ_DIR}/initrd.cpio.gz)
	(cd ${OBJ_DIR}/$<; mkimage -A arm -O linux -T ramdisk -C gzip -d ${OBJ_DIR}/initrd.cpio.gz $@)

${OBJ_DIR}/boot.scr:
	(cd $<; echo 'setenv bootargs console=ttyS0,115200 root=/dev/ram0 rdinit=/sbin/init rootdelay=2 loglevel=7' > boot.cmd)
	(cd $<; echo setenv bootcmd bootm 0x41000000 0x41c00000 0x41800000 >> boot.cmd)
	(cd $<; echo run bootcmd >> boot.cmd)
	(cd $<; mkimage -C none -A arm -T script -d boot.cmd ${OBJ_DIR}/boot.scr)

boot: ${OBJ_DIR}/boot.scr
	@sudo sunxi-fel -v uboot ${OBJ_DIR}/u-boot/orangepi_pc/u-boot-sunxi-with-spl.bin \
             write 0x41000000 ${OBJ_DIR}/boot/vmlinuz-lts \
             write 0x41800000 ${OBJ_DIR}/boot/dtbs-lts/sun8i-h2-plus-orangepi-zero.dtb \
             write 0x4fc00000 ${OBJ_DIR}/boot.scr \
             write 0x41C00000 ${OBJ_DIR}/initrd.cpio.gz.uboot

distclean: clean

clean:
	@rm -Rf ${OBJ_DIR}
