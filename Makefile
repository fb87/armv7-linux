
all: builder target

builder:
	docker build -t armhf-builder .

target: u-boot kernel
	mkdir -p output
	cp -Rf u-boot/*.bin .config output
	cp -Rf arch/arm/boot/*Image vmlinux .config output

u-boot:
	docker run --rm -it -v ${PWD}/u-boot:/work armhf-builder make -C /work LicheePi_Zero_defconfig
	docker run --rm -it -v ${PWD}/u-boot:/work armhf-builder make -C /work -j$(nproc)

kernel:
	docker run --rm -it -v ${PWD}/linux:/work armhf-builder make -C /work licheepi_zero_defconfig
	docker run --rm -it -v ${PWD}/linux:/work armhf-builder make -C /work -j$(nproc)

