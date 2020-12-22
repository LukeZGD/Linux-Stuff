#!/bin/bash

packages=(
audacious
audacious-plugins
audacity
ffmpegthumbs
fish
gimp
git
gnome-disk-utility
gparted
kate
kcalc
kdenlive
kfind
mpv
neofetch
obs-studio
okteta
openjdk-8-jre-headless
qbittorrent
qdirstat
samba
simple-scan
viewnior
winetricks
)

flatpkgs=(
us.zoom.Zoom
)

flatemus=(
io.mgba.mGBA
net.kuribo64.melonDS
net.pcsx2.PCSX2
org.DolphinEmu.dolphin-emu
org.ppsspp.PPSSPP
)

sudo dpkg --add-architecture i386
sudo apt purge -y gwenview kdeconnect kwrite snapd vlc
sudo apt autoremove -y
sudo apt update
sudo apt dist-upgrade -y

sudo add-apt-repository -y ppa:obsproject/obs-studio
sudo add-apt-repository -y ppa:ubuntuhandbook1/apps
sudo apt update

select opt in "NVIDIA Optimus+TLP" "NVIDIA 390xx"; do
    case $opt in
        "NVIDIA Optimus+TLP" ) sudo apt install -y nvidia-driver-455 libnvidia-gl-455:i386 tlp; break;;
        "NVIDIA 390xx" ) sudo apt install -y nvidia-driver-390 libnvidia-gl-390:i386; break;;
    esac
done    

sudo apt install -y ${packages[*]}

python3 -m pip install -U gallery-dl youtube-dl

flatpak install -y flathub ${flatpkgs[*]}
flatpak install -y flathub ${flatemus[*]}

wget -nc https://dl.winehq.org/wine-builds/winehq.key
sudo apt-key add winehq.key
rm winehq.key
sudo add-apt-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ focal main' 
sudo apt update
sudo apt install -y --install-recommends winehq-stable
winetricks -q gdiplus vcrun2013 vcrun2015 wmp9

sudo apt install -y virtualbox virtualbox-ext-pack virtualbox-guest-additions-iso
sudo usermod -aG vboxusers $USER
sudo modprobe vboxdrv
