# RADME

## List of Armv7 Embedded Linux based

* [Lichee Zero](https://github.com/fb87/armv7-linux/tree/lichee-zero-v3s) - Allwinner V3S based embedded board (1x1.2GHz, 32MiB DDR)
* [Orangepi Zero](https://github.com/fb87/armv7-linux/tree/orangepi-zero-h3) - Allwinner H3 based embedded board (4x1.2Ghz, 512MiB DDR)

All projects are built using Linux Container, the only host tools required are `docker|podman` (container engine), `make` (to build), `u-boot-tools` (for making images), `sunxi-tools` (for booting).

## To build

* Fetch source code `git submodule update --init` (this is need not if you clone the meta with `--recursive`)
* To build, simply hit `make all`
* To boot the board using FEL: `make boot`

## H/W setup

* FEL USB permission `sudo chmod 777 /dev/ttyUSB0` (or setting udev)
* Connect to serial port `screen /dev/ttyUSB0 115200` (Nix user: `nix run nixpkgs#screen -- /dev/ttyUSB0 115200`)


