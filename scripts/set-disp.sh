#!/bin/bash

display1="eDP-1"
display2="HDMI-1"
display2_connected=$(xrandr | grep -c "$display2 connected")

if [[ -n $1 ]]; then
    choice=$1
else
    choice=$(kdialog --title "Display" --radiolist "Set display configuration" display2 "External only" on display1 "Laptop only" off unify "Unify outputs" off epl "External [P], Laptop" off elp "External, Laptop [P]" off lpe "Laptop [P], External" off lep "Laptop, External [P]" off)
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
elif [[ $choice == "epl" ]]; then
    xrandr --output $display2 --primary --left-of $display1
elif [[ $choice == "elp" ]]; then
    xrandr --output $display1 --primary --right-of $display2
elif [[ $choice == "lpe" ]]; then
    xrandr --output $display1 --primary --left-of $display2
elif [[ $choice == "lep" ]]; then
    xrandr --output $display2 --primary --right-of $display1
fi
