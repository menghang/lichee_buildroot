#!/bin/bash
set -e

PLATFORM=""
MODULE=""

CUR_DIR=$PWD
OUT_DIR=$CUR_DIR/out
KERN_VER=2.6.36
KERN_DIR=$CUR_DIR/linux-${KERN_VER}
KERN_OUT_DIR=$KERN_DIR/output
BR_DIR=$CUR_DIR/buildroot
BR_OUT_DIR=$BR_DIR/output
U_BOOT_DIR=$CUR_DIR/u-boot


update_kdir()
{
	KERN_VER=$1
	KERN_DIR=${CUR_DIR}/linux-${KERN_VER}
	KERN_OUT_DIR=$KERN_DIR/output
}

show_help()
{
printf "
NAME
    build - The top level build script for Lichee Linux BSP

SYNOPSIS
    build [-h] | [-p platform] [-k kern_version] [-m module] | pack

OPTIONS
    -h             Display help message
    -p [platform]  platform, e.g. sun4i, sun4i-lite, sun4i-debug, sun4i_crane
                   sun4i: full linux bsp
                   sun4i-lite: linux bsp with less packages
                   sun4i-debug: linux bsp for debug
                   sun4i_crane: android kernel

    -k [kern_ver]  2.6.36(default), or 3.0                          [OPTIONAL]

    -m [module]    Use this option when you dont want to build all. [OPTIONAL]
                   e.g. kernel, buildroot, uboot, all(default)...
    pack           To start pack program

Examples:
    ./build.sh -p sun4i-lite
    ./build.sh -p sun4i_crane
    ./build.sh -p sun4i-lite
    ./build.sh pack

"

}

regen_rootfs()
{
	if [ -d ${BR_OUT_DIR}/target ]; then
		echo "Copy modules to target..."
		mkdir -p ${BR_OUT_DIR}/target/lib/modules
		rm -rf ${BR_OUT_DIR}/target/lib/modules/${KERN_VER}*
		cp -rf ${KERN_OUT_DIR}/lib/modules/* ${BR_OUT_DIR}/target/lib/modules/

		if [ "$PLATFORM" = "sun4i-debug" ]; then
			cp -rf ${KERN_DIR}/vmlinux ${BR_OUT_DIR}/target
		fi
	fi


	if [ "$PLATFORM" = "sun4i_crane" ]; then
		echo "Skip Regenerating Rootfs..."
	elif [ "$PLATFORM" = "sun4i-test" ]; then
		echo "Skip Regenerating Rootfs..."
	else
		echo "Regenerating Rootfs..."
		(cd ${BR_DIR}; make target-generic-getty-busybox; make target-finalize)
        	(cd ${BR_DIR};  make LICHEE_GEN_ROOTFS=y rootfs-ext4)
	fi
}

gen_output_sun3i()
{
	echo "output sun3i"
}

gen_output_generic()
{
	if [ ! -d "${OUT_DIR}" ]; then
		mkdir -pv ${OUT_DIR}
	fi

	cp -v ${BR_OUT_DIR}/images/* ${OUT_DIR}/
	cp -r ${KERN_OUT_DIR}/* ${OUT_DIR}/

	cp -v ${U_BOOT_DIR}/u-boot.bin ${OUT_DIR}/
	cp -v ${U_BOOT_DIR}/u-boot-mmc.bin ${OUT_DIR}/
}

gen_output_sun4i()
{
	gen_output_generic
}

gen_output_sun4i-lite()
{
	gen_output_generic
}

gen_output_sun4i-debug()
{
	gen_output_generic
}

gen_output_sun4i-test()
{
	if [ ! -d "${OUT_DIR}" ]; then
		mkdir -pv ${OUT_DIR}
	fi

	#cp -v ${BR_OUT_DIR}/images/* ${OUT_DIR}/
	cp -r ${KERN_OUT_DIR}/* ${OUT_DIR}/

	cp -v ${U_BOOT_DIR}/u-boot.bin ${OUT_DIR}/
	cp -v ${U_BOOT_DIR}/u-boot-mmc.bin ${OUT_DIR}/

	(cd $BR_DIR/target/test; fakeroot ./create_module_image.sh)
}

gen_output_sun5i()
{
	gen_output_generic
}

gen_output_a12()
{
	gen_output_generic
}

gen_output_a13()
{
	gen_output_generic
}

gen_output_sun4i_crane()
{
	if [ ! -d "${OUT_DIR}" ]; then
		mkdir -pv ${OUT_DIR}
	fi

	if [ ! -d "${OUT_DIR}/android" ]; then
		mkdir -p ${OUT_DIR}/android
	fi

	cp -r ${KERN_OUT_DIR}/* ${OUT_DIR}/android/
	mkdir -p ${OUT_DIR}/android/toolchain/
	cp ${BR_DIR}/dl/arm-2010.09-50-arm-none-linux-gnueabi-i686-pc-linux-gnu.tar.bz2 ${OUT_DIR}/android/toolchain/

	cp -v ${U_BOOT_DIR}/u-boot.bin ${OUT_DIR}/
	cp -v ${U_BOOT_DIR}/u-boot-mmc.bin ${OUT_DIR}/
}

clean_output()
{
	rm -rf ${OUT_DIR}/*
	rm -rf ${BR_OUT_DIR}/images/*
	rm -rf ${KERN_OUT_DIR}/*
}

if [ "$1" = "pack" ]; then
        ${BR_DIR}/scripts/build_pack.sh
        exit 0
fi

while getopts hp:m:k: OPTION
do
	case $OPTION in
	h) show_help
	exit 0
	;;
	p) PLATFORM=$OPTARG
	;;
	m) MODULE=$OPTARG
	;;
	k) KERN_VER=$OPTARG
	update_kdir $KERN_VER
	;;
	*) show_help
	exit 1
	;;
esac
done

if [ -z "$PLATFORM" ]; then
	show_help
	exit 1
fi

clean_output

if [ "$MODULE" = buildroot ]; then
	cd ${BR_DIR} && ./build.sh -p ${PLATFORM}
elif [ "$MODULE" = kernel ]; then
	export PATH=${BR_OUT_DIR}/external-toolchain/bin:$PATH
	cd ${KERN_DIR} && ./build.sh -p ${PLATFORM}
	regen_rootfs
	gen_output_${PLATFORM}
elif [ "$MODULE" = "uboot" ]; then
	case ${PLATFORM} in
	a12*)
		echo "build uboot for sun5i_a12"
		cd ${U_BOOT_DIR} && ./build.sh -p sun5i_a12
		;;
	a13*)
		echo "build uboot for sun5i_a13"
		cd ${U_BOOT_DIR} && ./build.sh -p sun5i_a13
		;;
	*)
		echo "build uboot for ${PLATFORM}"
		cd ${U_BOOT_DIR} && ./build.sh -p ${PLATFORM}
		;;
	esac
else
	cd ${BR_DIR} && ./build.sh -p ${PLATFORM}
	export PATH=${BR_OUT_DIR}/external-toolchain/bin:$PATH
	cd ${KERN_DIR} && ./build.sh -p ${PLATFORM}

	case ${PLATFORM} in
        a12*)
                echo "build uboot for sun5i_a12"
                #cd ${U_BOOT_DIR} && ./build.sh -p sun5i_a12
                ;;
        a13*)
                echo "build uboot for sun5i_a13"
                #cd ${U_BOOT_DIR} && ./build.sh -p sun5i_a13
                ;;
        sun4i-test)
               echo "build uboot for sun4i test"
               #cd ${U_BOOT_DIR} && ./build.sh -p sun4i
               ;;
        *)
                echo "build uboot for ${PLATFORM}"
                #cd ${U_BOOT_DIR} && ./build.sh -p ${PLATFORM}
                ;;
        esac

	regen_rootfs
	gen_output_${PLATFORM}
	echo "###############################"
	echo "#         compile success     #"
	echo "###############################"
	fi


