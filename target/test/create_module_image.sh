#!/bin/bash

BR_ROOT=`cd ../../; pwd`
LICHEE_ROOT=`cd $BR_ROOT/../; pwd`
LINUX_ROOT=`cd $LICHEE_ROOT/linux-3.0; pwd`

export PATH=$PATH:$BR_ROOT/target/tools/host/usr/bin


rm -rf modules/
mkdir modules

NR_SIZE=`du -s $LINUX_ROOT/output/lib/modules|awk '{print $1}'`
NEW_NR_SIZE=0
TARGET_IMAGE=modules.ext4

((NEW_NR_SIZE=$NR_SIZE+4096))


echo "blocks: $NR_SIZE -> $NEW_NR_SIZE"
genext2fs -d $LINUX_ROOT/output/lib/modules -b $NEW_NR_SIZE $TARGET_IMAGE

tune2fs -j -O extents,uninit_bg,dir_index $TARGET_IMAGE

fsck.ext4 -y $TARGET_IMAGE



