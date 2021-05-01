#!/bin/bash

Main() {
    Loop=1
    while [ $Loop == 1 ]; do
        Choice=$(kdialog --title "system76-power" --radiolist "system76-power" 1 "Graphics" on 2 "Profile" off)
        if [ ! -z $Choice ]; then
            Choices
        else
            Loop=0
        fi
    done
}

Choices() {
    if [ $Choice == 1 ]; then
        Graphics=$(kdialog --title "Graphics" --radiolist "Current setting: $(system76-power graphics)\nPower: $(system76-power graphics power)" integrated "Integrated" on nvidia "NVIDIA" off hybrid "Hybrid" off)
        [ ! -z $Graphics ] && konsole -e "bash -c 'system76-power graphics $Graphics'" && Loop=0
    elif [ $Choice == 2 ]; then
        Profile=$(kdialog --title "Profile" --radiolist "$(system76-power profile)" battery "Battery" off balanced "Balanced" on performance "Performance" off)
        [ ! -z $Profile ] && system76-power profile $Profile && Loop=0
    fi
}

Main
