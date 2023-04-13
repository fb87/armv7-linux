all: builder target

builder:
	@docker build -t armhf-builder .

output:
	@rm -Rf $@ && mkdir -p $@

target: output output/uImage output/u-boot.bin output/initrd.cpio.gz.uboot
	@cp -Rf src/busybox/{.config,busybox,initrd.cpio.gz.uboot} output
	@echo "-Output Artifacts------------------------------------"
	@ls -al output

output/initrd.cpio.gz.uboot: output/lichee
	@cp -Rf output/lichee   ${PWD}/src/busybox # make the modules visible to initrd
	@docker run --rm -it -v ${PWD}/src:/work -w /work/busybox armhf-builder make defconfig
	@docker run --rm -it -v ${PWD}/src:/work -w /work/busybox armhf-builder /bin/bash -c "echo CONFIG_STATIC=y >> .config"
	@docker run --rm -it -v ${PWD}/src:/work -w /work/busybox armhf-builder make install
	@docker run --rm -it -v ${PWD}/src:/work -w /work/busybox/_install armhf-builder /bin/bash -c \
		"rm -Rf initrd* etc && \
		cp -Rf ../lichee/lib . && \
		mkdir -p etc/init.d proc sys && \
		echo 'mount -t proc  none /proc && mount -t sysfs none /sys && mdev -s' > etc/init.d/rcS && \
		chmod +x etc/init.d/rcS && \
		find . | cpio --quiet -H newc -o | gzip -9 -n > /tmp/initrd.cpio.gz && \
		mkimage -A arm -O linux -T ramdisk -C gzip -d /tmp/initrd.cpio.gz ../initrd.cpio.gz.uboot"

output/u-boot.bin: output
	@docker run --rm -it -v ${PWD}/src:/work armhf-builder make -C /work/u-boot LicheePi_Zero_defconfig
	@docker run --rm -it -v ${PWD}/src:/work armhf-builder make -C /work/u-boot -j$(nproc)
	@cp -f src/u-boot/*.bin output
	@cp -f src/u-boot/.config output/u-boot.config

output/uImage: output
	@docker run --rm -it -v ${PWD}/src:/work -w /work/linux armhf-builder make licheepi_zero_defconfig
	@docker run --rm -it -v ${PWD}/src:/work -w /work/linux armhf-builder make uImage LOADADDR=0x40008000 -j$(nproc)
	@docker run --rm -it -v ${PWD}/src:/work -w /work/linux armhf-builder make modules dtbs -j$(nproc)
	@docker run --rm -it -v ${PWD}/src:/work -w /work/linux armhf-builder make modules_install INSTALL_MOD_PATH=./lichee
	@cp -f src/linux/arch/arm/boot/*Image src/linux/vmlinux src/linux/.config output
	@cp -f src/linux/.config output/linux.config
	@cp -f src/linux/arch/arm/boot/dts/sun8i-v3s-licheepi-zero*dtb output
	@cp -Rf src/linux/lichee output/

output/boot.scr:
	@docker run --rm -it -v ${PWD}/src:/work -w /work/busybox armhf-builder /bin/bash -c \
	"echo setenv bootargs console=ttyS0,115200 root=/dev/ram0 rdinit=/sbin/init rootdelay=2 loglevel=7 > boot.cmd && \
	echo setenv bootcmd bootm 0x41000000 0x41c00000 0x41800000 >> boot.cmd && \
	echo run bootcmd >> boot.cmd && \
	mkimage -C none -A arm -T script -d boot.cmd boot.scr"
	@cp ${PWD}/src/busybox/boot.scr output

boot: output/boot.scr
	@sudo sunxi-fel -v uboot output/u-boot-sunxi-with-spl.bin \
             write 0x41000000 output/uImage \
             write 0x41800000 output/sun8i-v3s-licheepi-zero-with-800x480-lcd.dtb \
             write 0x4fc00000 output/boot.scr \
             write 0x41C00000 output/initrd.cpio.gz.uboot

distclean: clean
	@make -C src/linux distclean
	@make -C src/u-boot distclean

clean:
	@rm -Rf output
