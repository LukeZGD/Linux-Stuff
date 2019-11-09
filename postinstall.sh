#!/bin/bash

packages=(ncurses5-compat-libs python2-twodict-git chromium-widevine chromium-vaapi-bin cydia-impactor gallery-dl github-desktop-bin input-veikk-dkms qdirstat ttf-ms-fonts ttf-tahoma ttf-vista-fonts uget-integrator uget-integrator-browsers vlc-plugin-fluidsynth youtube-dl-gui-git yay-bin)

for package in "${packages[@]}"
do
    sudo pacman -U --noconfirm AUR/$package/*.xz
done

echo "Laptop? (y/n)"
read laptop
if [ $laptop == y ]
then
    sudo pacman -S --noconfirm nvidia-dkms bbswitch-dkms tlp
    sudo pacman -U --noconfirm AUR/optimus-manager/*.xz
    sudo pacman -U --noconfirm AUR/optimus-manager-qt/*.xz
fi

echo "Install virtualbox? (y/n)"
read virtbox
if [ $virtbox == y ]
then
    sudo ./vbox.sh
fi
