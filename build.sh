#!/bin/sh
rm -rf ./out

# Compile
cd rockchip-u-boot
make ARCH=arm -j16 CROSS_COMPILE=aarch64-linux-gnu- distclean
make ARCH=arm -j16 CROSS_COMPILE=aarch64-linux-gnu- pinebookpro-rk3399_defconfig all

# Get the binaries and clean up
mkdir out
mv ./u-boot-dtb.bin ./out/
mv ./u-boot-dtb.img ./out/
mv out ../
make ARCH=arm -j16 CROSS_COMPILE=aarch64-linux-gnu- distclean
cd ../


# Assemble image for SD/eMMC card
mkdir sd
cd sd
mkimage -n rk3399 -T rksd -d ../rkbin/bin/rk33/rk3399_ddr_933MHz_v1.24.bin idbloader.img
cat ../rkbin/bin/rk33/rk3399_miniloader_v1.19.bin >> idbloader.img
../rkbin/tools/loaderimage --pack --uboot ../out/u-boot-dtb.img u-boot.img 0x200000
cp ../rkbin/RKTRUST/RK3399TRUST.ini ./trust.ini
sed -i "s:bin/:../rkbin/bin/:" trust.ini
../rkbin/tools/trust_merger trust.ini
cd ../
mv ./sd ./out/

# Create SPI firmware from Rockchip blobs and compiled U-Boot
./rkbin/tools/loaderimage --pack --uboot ./out/u-boot-dtb.bin u-boot.img 0x200000
./rkbin-radxa/tools/firmwareMerger -P spi.ini ./

# Clean up
rm ./u-boot.img
mkdir ./out/spi
rm ./Firmware.md5
mv ./Firmware.img ./out/spi/spiflash.bin
cd ./out/spi
sha256sum spiflash.bin > spiflash.sha256
cd .././
