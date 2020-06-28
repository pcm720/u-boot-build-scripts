#!/bin/bash
EXTRA="pcm720"

rm -rf build
mkdir build

##
# ATF
##
cd arm-trusted-firmware
# Apply ATF patches
for p in ../patches/atf/*.patch;  do
    git am $p
done
# Build ATF
make realclean
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=rk3399 bl31
cp build/rk3399/release/bl31/bl31.elf ../build/
make realclean
cd ..

##
# U-Boot
##
cd u-boot
# Apply U-Boot patches
for p in ../patches/u-boot/*.patch;  do
    git am $p
done
# Configure and copy ATF
make mrproper
cp ../build/bl31.elf ./
make pinebook-pro-rk3399_defconfig
# Build
make -j$(getconf _NPROCESSORS_ONLN) CROSS_COMPILE=aarch64-linux-gnu- EXTRAVERSION=-$EXTRA
# Generate SPI image
tools/mkimage -n rk3399 -T rkspi -d tpl/u-boot-tpl-dtb.bin:spl/u-boot-spl-dtb.bin idbloader-spi.img
cat <(dd if=idbloader-spi.img bs=512K conv=sync) u-boot.itb > spiflash.bin
# Copy binaries to build directory
cp spiflash.bin ../build
cp idbloader-spi.img ../build
cp idbloader.img ../build
cp u-boot.itb ../build
# Cleanup
make mrproper
# dd idbloader seek 64 conv notrunc
# dd u-boot.itb seek16384 conv notrunc
