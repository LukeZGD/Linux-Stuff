#!/bin/bash

function deedee {
    if [ ! -z $1 ] && [ ! -z $2 ]; then
        Input=$1
        Output=$2
    else
        read -p "[Input] Path to image file (drag image file to terminal window): " Input
        lsblk
        read -p "[Input] Disk output? (/dev/sdX): " Output
    fi
    Input="${Input%\'}"
    Input="${Input#\'}"
    echo "Input: $Input"
    echo "Output: $Output"
    echo "Starting in 5 seconds..."
    sleep 5
    sudo dd if="$Input" of="$Output" bs=4M conv=fsync status=progress
}

function rsyncee {
    if [ ! -z $1 ] && [ ! -z $2 ]; then
        Input=$1
        Output=$2
        Type=$3
    else
        read -p "[Input] Input directory (drag folder to terminal window): " Input
        read -p "[Input] Output directory (drag folder to terminal window): " Output
        read -p "[Input] Type? {type1(va,default)|type2(vrltD)} " Type
    fi
    if [[ $Type == 2 ]]; then
        Type=-vrltD
    else
        Type=-va
    fi
    echo "Input: $Input"
    echo "Output: $Output"
    echo "Type: $Type"
    echo "Starting in 5 seconds..."
    sleep 5
    rsync $Type --update --delete-after --info=progress2 "$Input" "$Output"
}

if [[ $1 == dd ]]; then
    deedee $2 $3
elif [[ $1 == rsync ]]; then
    rsyncee $2 $3 $4
else
    echo "Usage:  lgdutil {dd|rsync} [options]
    dd usage:    lgdutil dd [input] [output]
    rsync usage: lgdutil rsync [input] [output] {type1(va,default)|type2(vrltD)}"
fi
