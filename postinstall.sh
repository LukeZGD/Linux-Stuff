#!/bin/bash

packages=(ncurses5-compat-libs python2-twodict-git cydia-impactor gallery-dl github-desktop-bin qdirstat ttf-ms-fonts ttf-tahoma ttf-vista-fonts uget-integrator uget-integrator-browsers vlc-plugin-fluidsynth youtube-dl-gui-git yay)

echo "run as root (sudo)"
read

for package in "${packages[@]}"
do
    pacman -U --noconfirm AUR/$package/*.xz
done

echo "Laptop? (y/n)"
read laptop
if [ $laptop == y ]
then
    pacman -S --noconfirm nvidia-dkms bbswitch-dkms tlp
    pacman -U --noconfirm AUR/optimus-manager/*.xz
    pacman -U --noconfirm AUR/optimus-manager-qt/*.xz
fi

echo "Install virtualbox? (y/n)"
read virtbox
if [ $virtbox == y ]
then
    ./vbox.sh
fi

echo "Install osu? (y/n)"
read oss
if [ $oss == y ]
then
    ./osu.sh
fi
