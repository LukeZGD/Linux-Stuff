#!/bin/bash

if [ ! -z $1 ] && [ ! -z $2 ]; then
    Input=$1
    Output=$2
elif [[ $1 == help ]]; then
    echo "Usage:  deedee [input] [output]"
    exit
else
    echo "Usage:  deedee [input] [output]"
    read -p "[Input] Path to image file (drag image file to terminal window): " Input
    lsblk
    read -p "[Input] Disk output? (/dev/sdX): " Output
fi
echo "Input: $Input"
echo "Output: $Output"
echo "Starting in 5 seconds..."
sleep 5
sudo dd if="$Input" of="$Output" bs=4M conv=fsync status=progress
