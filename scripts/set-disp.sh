#!/bin/bash

display1="eDP-1"
display2="HDMI-1"

if [[ $(xrandr | grep -c "$display2 connected") == 1 ]]; then
    display2_connected=1
fi

if [[ ! -z $1 ]]; then
    choice=$1
else
    choice=$(kdialog --title "Display" --radiolist "Set display configuration" display2 "External screen" on display1 "Laptop screen" off unify "Unify outputs" off left "Extend to left" off right "Extend to right" off)
fi

if [[ -z $choice ]]; then
    exit
fi

echo $choice

xrandr --output $display1 --auto
xrandr --output $display2 --auto

if [[ $choice == "display1" ]]; then
    xrandr --output $display2 --off
elif [[ $choice == "display2" && $display2_connected == 1 ]]; then
    xrandr --output $display1 --off
elif [[ $choice == "unify" && $display2_connected == 1 ]]; then
    xrandr --output $display2 --same-as $display1
elif [[ $choice == "left" ]]; then
    xrandr --output $display2 --primary --left-of $display1
elif [[ $choice == "right" ]]; then
    xrandr --output $display1 --primary --left-of $display2
fi
