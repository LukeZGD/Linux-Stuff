#!/bin/bash

packages=(ncurses5-compat-libs python2-twodict-git chromium-vaapi-bin chromium-widevine cydia-impactor gallery-dl github-desktop-bin input-veikk-dkms qdirstat ttf-ms-fonts ttf-tahoma ttf-vista-fonts uget-integrator uget-integrator-browsers vlc-plugin-fluidsynth woeusb youtube-dl-gui-git yay-bin)

for package in "${packages[@]}"
do
    sudo pacman -U --noconfirm AUR/$package/*.xz
done

echo "Laptop? (y/n)"
read laptop
if [ $laptop == y ]
then
    sudo pacman -S --noconfirm nvidia-dkms nvidia-settings bbswitch-dkms tlp
    sudo pacman -U --noconfirm AUR/optimus-manager/*.xz
    sudo pacman -U --noconfirm AUR/optimus-manager-qt/*.xz
fi

echo "PC? (y/n)"
read pc
if [ $pc == y ]
then
    sudo pacman -S --noconfirm nvidia-390xx-dkms nvidia-390xx-settings
fi

echo "Install virtualbox? (y/n)"
read virtbox
if [ $virtbox == y ]
then
    sudo ./vbox.sh
fi
