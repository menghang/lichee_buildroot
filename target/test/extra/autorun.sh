#!/bin/sh

#wait for dwin
#logw "Begin to test memory..."
#infow 0 MEM "Testing, please wait.."
#memtester 1M 1
#RESULT=$?
#infow 0 MEM "result $RESULT"
#logw "Memory test result: $RESULT"


insmod /lib/modules/`uname -r`/sun4i-keyboard.ko

CSI_FIRST_TIME=0

process_csi()
{
        if [ "$CSI_FIRST_TIME" -eq 0 ]; then
                insmod /lib/modules/`uname -r`/videobuf-core.ko
                insmod /lib/modules/`uname -r`/videobuf-dma-contig.ko
                CSI_FIRST_TIME=1
        else
                echo "CSI: Not first load"
        fi

        case $1 in
        csi0_para)
                CSI0_MOD=`script_list_skey -f /boot/script0.bin -m csi0_para |grep "csi_mname\>"| awk '{print $2}'`
                if [ -f /lib/modules/`uname -r`/$CSI0_MOD.ko ]; then
                        echo "Load $CSI0_MOD driver(csi0)"
                        insmod /lib/modules/`uname -r`/$CSI0_MOD.ko
                fi
                insmod /lib/modules/`uname -r`/sun4i_csi0.ko
                ;;
        csi1_para)
                CSI1_MOD=`script_list_skey -f /boot/script0.bin -m csi1_para |grep "csi_mname\>"| awk '{print $2}'`
                if [ -f /lib/modules/`uname -r`/$CSI1_MOD.ko ]; then
                        echo "Load $CSI1_MOD driver(csi1)"
                        insmod /lib/modules/`uname -r`/$CSI1_MOD.ko
                fi
                insmod /lib/modules/`uname -r`/sun4i_csi1.ko
                ;;
        esac

}

IS_USB_WIFI=0

do_usb_wifi()
{
        echo "usb_wifi"
	insmod /lib/modules/`uname -r`/8192cu.ko
	IS_USB_WIFI=1
}


do_sdio_wifi()
{
        echo "sdio_wifi"
	IS_USB_WIFI=0
}


for mod in $(script_list_mkey -f /boot/script0.bin); do
case $mod in
ir_para)
        insmod /lib/modules/`uname -r`/sun4i-ir.ko
        ;;
dram_para)
        DRM_CLK=`script_list_skey -f /boot/script0.bin -m dram_para |grep dram_clk |awk '{print $2}'`
        ;;
ctp_para)
        CTP_NAME=`script_list_skey -f /boot/script0.bin -m ctp_para |grep ctp_name| awk '{print $2}'`
        case $CTP_NAME in
        Goodix-TS)
                insmod /lib/modules/`uname -r`/goodix_touch.ko
                ;;
        ft5x_ts)
                insmod /lib/modules/`uname -r`/ft5x_ts.ko
                ;;
        *)
                echo "Unsupported CTP detected"
                ;;
        esac
        ;;
rtp_para)
	insmod /lib/modules/`uname -r`/sun4i-ts.ko
        ;;
motor_para)
	insmod /lib/modules/`uname -r`/sun4i-vibrator.ko
        ;;
csi[01]_para)
        process_csi $mod
        ;;
usb_wifi_para)
        do_usb_wifi
        ;;
sdio_wifi_para)
        do_sdio_wifi
        ;;
gsensor_para)
	GS_NAME=`script_list_skey -f /boot/script0.bin -m gsensor_para |grep gsensor_name| awk '{print $2}'`
	insmod /lib/modules/`uname -r`/$GS_NAME.ko
	;;

esac

done


for dev in $(cd /sys/class/input/; ls event*); do
	DNAME=`cat /sys/class/input/$dev/device/name`
	case $DNAME in
	ft5x_ts)
		export TSLIB_TSDEVICE=/dev/input/$dev
		;;
	Goodix-TS)
		export TSLIB_TSDEVICE=/dev/input/$dev
		;;
	sun4i-ts)
		export TSLIB_TSDEVICE=/dev/input/$dev
		ts_calibrate
		;;
	*)
		;;
        esac
done

######################################
#
#  start GUI
#
######################################
dwin &
inotify-disk /dev &
sleep 1

infow2 12 1 GSR "Fail"

# IR , Key, Gsensor
for dev in $(cd /sys/class/input/; ls event*); do
	DNAME=`cat /sys/class/input/$dev/device/name`
	case $DNAME in
	*keyboard)
		evtest-key /dev/input/$dev &
		;;
	*-ir)
		evtest-ir /dev/input/$dev 2>&1 1>/dev/null &
		;;
	mma*)
		infow2 12 2 GSR "$DNAME OK"
		logw "gsensor: `cat /sys/class/input/$dev/device/value`"
		;;
	bma*)
		infow2 12 2 GSR "$DNAME OK"
		logw "gsensor: `cat /sys/class/input/$dev/device/value`"
		;;
	*ts)
		evtest-ts /dev/input/$dev 2>&1 1>/dev/null &
		;;
	*)
		logw "unkown input device name"
		;;
	esac
done

misc 2>&1 1>/dev/null &
audio-test.sh 2>&1 1>/dev/null &
csi-test.sh 2>&1 1>/dev/null &
wireless-test.sh $IS_USB_WIFI 2>&1 1>/dev/null &

# memory test
logw "mem testing, please wait..."
memtester 1M 1
RESULT=$?
if [ "$RESULT" -eq 0 ]; then
	infow2 0 2 MEM "OK"
else
	infow2 0 1 MEM "Failed"
fi
logw "Memory test result: $RESULT"




