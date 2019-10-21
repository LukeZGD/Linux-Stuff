#!/bin/bash

packages=(ncurses5-compat-libs python2-twodict-git cydia-impactor gallery-dl qdirstat ttf-ms-fonts ttf-tahoma ttf-vista-fonts uget-integrator uget-integrator-browsers vlc-plugin-fluidsynth youtube-dl-gui-git yay)

for package in "${packages[@]}"
do
    pacman -U --noconfirm AUR/$package/*.xz
done

