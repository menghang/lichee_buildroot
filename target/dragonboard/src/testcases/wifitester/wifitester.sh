#!/bin/sh

source send_cmd_pipe.sh
source script_parser.sh

module_path=`script_fetch "wifi" "module_path"`
module_args=`script_fetch "wifi" "module_args"`

if [ -z "$module_path" ]; then
    SEND_CMD_PIPE_FAIL $3
    exit 1
fi

echo "insmod $module_path $module_args"
insmod "$module_path" "$module_args"
if [ $? -ne 0 ]; then
    SEND_CMD_PIPE_FAIL $3
    exit 1
fi

# wait for wifi initialize finish
sleep 3

while true; do
    if ifconfig -a | grep wlan0; then
        ifconfig wlan0 up
        if [ $? -ne 0 ]; then
            SEND_CMD_PIPE_FAIL $3
            exit 1
        fi
        for item in $(iwlist wlan0 scan | grep SSID); do
            item=`echo $item | awk -F: '{print $2}'`
            if [ -n "$item" ]; then
                break
            fi
        done
        if [ -z "$item" ]; then
            SEND_CMD_PIPE_FAIL $3
            exit 1
        fi
        SEND_CMD_PIPE_OK_EX $3 $item
    fi

    ifconfig wlan0 down
    if [ $? -ne 0 ]; then
        SEND_CMD_PIPE_FAIL $3
        exit 1
    fi
    sleep 5
done
