#!/bin/sh

CSI_OUT=""

while true;

do

for item in $(ls /dev/video*); do
	csi $item 2>&1 1>/dev/null
	RESULT=$?
	if [ $RESULT -eq 0 ]; then
		CSI_OUT="$CSI_OUT $item OK"
		COLOR="2"
	else
		CSI_OUT="$item Fail"
		COLOR="1"
	fi
done

CSI_OUT1=`echo $CSI_OUT|sed 's/\/dev\/video/csi/g'`

infow2 13 $COLOR CSI "$CSI_OUT1"

sleep 10

CSI_OUT=""
COLOR=""

done






