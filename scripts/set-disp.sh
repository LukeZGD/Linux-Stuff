#!/bin/bash

if [[ $XDG_SESSION_TYPE == "x11" ]]; then
    display1="eDP-1"
    display2="HDMI-1"
elif [[ $XDG_SESSION_TYPE == "wayland" ]]; then
    display1="1"
    display2="2"
fi
#display2_connected=$(xrandr | grep -c "$display2 connected")
display2_connected=$(kscreen-doctor -o | grep "HDMI" | grep -c "connected")
mode1="1920x1080@60"
mode2="$mode1"
width1=$(echo $mode1 | cut -c -4)
width2=$(echo $mode2 | cut -c -4)

if [[ -n $1 ]]; then
    choice=$1
else
    choice=$(kdialog --title "Display" --radiolist "Set display configuration" display2 "External only" on display1 "Laptop only" off unify "Unify outputs" off epl "External [P], Laptop" off elp "External, Laptop [P]" off lpe "Laptop [P], External" off lep "Laptop, External [P]" off)
fi

if [[ -z $choice ]]; then
    exit
fi

echo $choice

#xrandr --output $display1 --auto
#xrandr --output $display2 --auto

if [[ $choice == "display1" ]]; then
    #xrandr --output $display2 --off
    kscreen-doctor output.$display2.disable output.$display1.enable
elif [[ $choice == "display2" && $display2_connected == 1 ]]; then
    #xrandr --output $display1 --off
    kscreen-doctor output.$display1.disable output.$display2.enable
elif [[ $choice == "unify" && $display2_connected == 1 ]]; then
    #xrandr --output $display2 --same-as $display1
    kscreen-doctor output.$display2.enable output.$display1.enable
    kscreen-doctor output.$display2.position.0,0 output.$display1.position.0,0
elif [[ $choice == "epl" ]]; then
    #xrandr --output $display2 --primary --left-of $display1
    kscreen-doctor output.$display2.enable output.$display1.enable
    kscreen-doctor output.$display2.position.0,0 output.$display1.position.$width2,0
    kscreen-doctor output.$display2.primary
elif [[ $choice == "elp" ]]; then
    #xrandr --output $display1 --primary --right-of $display2
    kscreen-doctor output.$display1.enable output.$display2.enable
    kscreen-doctor output.$display1.position.0,$width2 output.$display2.position.0,0
    kscreen-doctor output.$display1.primary
elif [[ $choice == "lpe" ]]; then
    #xrandr --output $display1 --primary --left-of $display2
    kscreen-doctor output.$display1.enable output.$display2.enable
    kscreen-doctor output.$display1.position.0,0 output.$display2.position.$width1,0
    kscreen-doctor output.$display1.primary
elif [[ $choice == "lep" ]]; then
    #xrandr --output $display2 --primary --right-of $display1
    kscreen-doctor output.$display2.enable output.$display1.enable
    kscreen-doctor output.$display2.position.$width1,0 output.$display1.position.0,0
    kscreen-doctor output.$display2.primary
fi
