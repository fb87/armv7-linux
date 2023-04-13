# RADME

## Inputs

* [Linux Kernel](https://github.com/Lichee-Pi/linux) - branch `zero-5.2.y`
* [U-Boot](git://git.denx.de/u-boot-sunxi.git)

## Host env. preparation

* Install either `Docker` or `Podman` plus `gnumake` for building
* Install `sunxi-tools` for flashing

## Build procedures

* Simply hit `make`

## Booting

* Boot using [sunxi-fel](https://linux-sunxi.org/FEL/USBBoot)

Lichee Zero boots with RAM base at `0x40000000`, check [here](https://source.denx.de/u-boot/u-boot/blob/master/include/configs/sunxi-common.h)

```c
#define SDRAM_OFFSET(x) 0x4##x
#define CFG_SYS_SDRAM_BASE		0x40000000
/* V3s do not have enough memory to place code at 0x4a000000 */

....

#elif (CONFIG_SUNXI_MINIMUM_DRAM_MB >= 64)

/*
 * 64M RAM minus 2MB heap + 16MB for u-boot, stack, fb, etc.
 * 16M uncompressed kernel, 8M compressed kernel, 1M fdt,
 * 1M script, 1M pxe, 1M dt overlay and the ramdisk at the end.
 */

#define BOOTM_SIZE        __stringify(0x2e00000)
#define KERNEL_ADDR_R     __stringify(SDRAM_OFFSET(1000000))
#define FDT_ADDR_R        __stringify(SDRAM_OFFSET(1800000))
#define SCRIPT_ADDR_R     __stringify(SDRAM_OFFSET(1900000))
#define PXEFILE_ADDR_R    __stringify(SDRAM_OFFSET(1A00000))
#define FDTOVERLAY_ADDR_R __stringify(SDRAM_OFFSET(1B00000))
#define RAMDISK_ADDR_R    __stringify(SDRAM_OFFSET(1C00000))
```

Boot commands:

```
sunxi-fel -v uboot output/u-boot-sunxi-with-spl.bin \
▏  write 0x41000000 output/uImage \
▏  write 0x41800000 output/sun8i-v3s-licheepi-zero.dtb \
▏  write 0x4fc00000 output/boot.scr \
▏  write 0x41C00000 output/initrd.cpio.gz.uboot

```

Mount sysfs & procfs if not yet done (Error message such as `can't open /dev/tty3: No such file or directory` will be output continously)

```
mkdir -p /sys /proc

mount -t proc  none /proc
mount -t sysfs none /sys

mdev -s
```
