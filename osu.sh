#!/bin/bash

echo "uncomment multilib [will open nano] [Press enter]"
read
sudo nano /etc/pacman.conf
sudo pacman -Sy

cd osuscript
sudo cp limits.conf /etc/security

sudo mkdir /etc/pulse/daemon.conf.d
sudo cp 10-better-latency.conf /etc/pulse/daemon.conf.d

sudo cp osu /usr/bin
sudo cp osukill /usr/bin
sudo chmod +x /usr/bin/osu
sudo chmod +x /usr/bin/osukill

pactl list sinks > sinks
xed notes
xed sinks
sudo nano /etc/pulse/default.pa


echo "390xx or nah (y/n)"
read sel
if [ $sel == y ]
then
    sudo pacman -S --noconfirm lib32-nvidia-390xx-utils
else
    sudo pacman -S --noconfirm lib32-nvidia-utils
fi
sudo pacman -S --noconfirm winetricks lib32-libxcomposite lib32-gnutls
sudo pacman -U --noconfirm wine-osu-3.12-1-x86_64.pkg.tar.xz

cp -R /run/media/lukee/LukeHDDNew/Inst_Arch/dotcache/winetricks /home/lukee/.cache

export WINEPREFIX="$HOME/.wine_osu" # This is the path to a hidden folder in your home folder.
export WINEARCH=win32 # Only needed when executing the first command with that WINEPREFIX
export PATH=/opt/wine-osu/bin:$PATH

winetricks dotnet40
winetricks gdiplus
winetricks cjkfonts

rm -rf /home/lukee/.cache/winetricks
