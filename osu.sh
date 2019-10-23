#!/bin/bash

sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
sudo pacman -Sy

cd osuscript
sudo echo "@audio - nice -20
@audio - rtprio 99 " >> /etc/security/limits.conf

sudo mkdir /etc/pulse/daemon.conf.d
sudo echo "high-priority = yes
nice-level = -15

realtime-scheduling = yes
realtime-priority = 50

resample-method = speex-float-0

default-fragments = 2 # Minimum is 2
default-fragment-size-msec = 4" > /etc/pulse/daemon.conf.d/10-better-latency.conf

sudo cp osu /usr/bin
sudo cp osukill /usr/bin
sudo chmod +x /usr/bin/osu
sudo chmod +x /usr/bin/osukill

sink=$(pacmd info |grep "Default sink name" |cut -c 20-)

sudo sed -i "s/load-module module-udev-detect/load-module module-udev-detect tsched=0 fixed_latency_range=yes/" /etc/pulse/default.pa
sudo echo "load-module module-null-sink sink_name=\"audiocap\" sink_properties=device.description=\"audiocap\"
load-module module-loopback latency_msec=1 sink=\"audiocap\" source=\"$sink.monitor\"" >> /etc/pulse/default.pa

echo "390xx or nah (y/n)"
read sel
if [ $sel == y ]
then
    sudo pacman -S --noconfirm lib32-nvidia-390xx-utils
fi
echo "nvidia or nah (y/n)"
read nvidia
if [ $nvidia == y ]
then
    sudo pacman -S --noconfirm lib32-nvidia-utils
fi
sudo pacman -S --noconfirm winetricks lib32-libxcomposite lib32-gnutls
sudo pacman -U --noconfirm wine-osu-3.12-2-x86_64.pkg.tar.xz

cp -R /run/media/lukee/LukeHDDNew/Inst_Arch/dotcache/winetricks /home/lukee/.cache

export WINEPREFIX="$HOME/.wine_osu" # This is the path to a hidden folder in your home folder.
export WINEARCH=win32 # Only needed when executing the first command with that WINEPREFIX
export PATH=/opt/wine-osu/bin:$PATH

winetricks dotnet40
winetricks gdiplus
winetricks cjkfonts

rm -rf /home/lukee/.cache/winetricks
echo "Preparations complete. Download and install osu! now? (y/n) (needs wget)"
read installoss
if [ $installoss == y ]
then
    wget 'https://m1.ppy.sh/r/osu!install.exe'
    wine 'osu!install.exe'
fi
echo "Script done"
