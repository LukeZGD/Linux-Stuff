#!/bin/bash

Deedee() {
    Input="$1"
    Output="$2"
    if [[ -z $1 || -n $2 ]]; then
        read -r -p "[Input] Path to image file (drag image file to terminal window): " Input
        lsblk
        read -r -p "[Input] Disk output? (/dev/sdX): " Output
    fi

    echo "Input: $Input"
    echo "Output: $Output"
    echo "Starting in 5 seconds..."
    sleep 5
    sudo dd if="$Input" of="$Output" bs=4M conv=fsync status=progress
}

RSyncee() {
    Input="$1"
    Output="$2"
    Type="-va"
    if [[ -z $1 || -z $2 ]]; then
        read -r -p "[Input] Input directory (drag folder to terminal window): " Input
        read -r -p "[Input] Output directory (drag folder to terminal window): " Output
        read -r -p "[Input] Type? {\"type1\" for -va (default), \"type2\" for -vrltD}: " Type
    fi
    if [[ $Type == '2' || $Type == "type2" ]]; then
        Type="-vrltD"
    fi

    echo "Input: $Input"
    echo "Output: $Output"
    echo "Type: $Type"
    echo "Starting in 5 seconds..."
    sleep 5
    rsync $Type --update --del --info=progress2 "$Input" "$Output"
}

if [[ $1 == dd ]]; then
    Deedee "$2" "$3"
elif [[ $1 == rsync ]]; then
    RSyncee "$2" "$3" "$4"
else
    echo "Usage:  lgdutil {dd|rsync} [options]
    dd usage:    lgdutil dd [input] [output]
    rsync usage: lgdutil rsync [input] [output] {\"type1\" for -va (default), \"type2\" for -vrltD}"
fi
