#!/bin/bash

packages=(
audacious
audacious-plugins-amidi
audacious-plugins-freeworld
audacity
ffmpeg
ffmpegthumbs
fish
gimp
git
gnome-calculator
gnome-disk-utility
google-noto-sans-fonts
gparted
hplip
htop
kate
kdenlive
java-11-openjdk
mpv
neofetch
obs-studio
okteta
persepolis
qbittorrent
qdirstat
simple-scan
)

flatpkgs=(
org.gtk.Gtk3theme.Breeze
)

flatemus=(
ca._0ldsk00l.Nestopia
com.snes9x.Snes9x
io.mgba.mGBA
net.kuribo64.melonDS
net.pcsx2.PCSX2
org.DolphinEmu.dolphin-emu
org.ppsspp.PPSSPP
)

MainMenu() {
    select opt in "Install stuff" "Run postinstall commands" "pip install/update" "Backup and restore" "NVIDIA"; do
        case $opt in
            "Install stuff" ) installstuff; break;;
            "Run postinstall commands" ) postinstall; break;;
            "pip install/update" ) pipinstall; break;;
            "Backup and restore" ) $HOME/Arch-Stuff/postinst.sh BackupRestore; break;;
            "NVIDIA" ) nvidia; break;;
            * ) exit;;
        esac
    done
}

installstuff() {
    select opt in "VirtualBox" "wine" "osu!" "Emulators"; do
        case $opt in
            "VirtualBox" ) vbox; break;;
            "wine" ) wine; break;;
            "osu!" ) $HOME/Arch-Stuff/scripts/osu.sh install; break;;
            "Emulators" ) emulatorsinstall; break;;
            * ) exit;;
        esac
    done
}

nvidia() {
    select opt in "NVIDIA Optimus+TLP" "NVIDIA 390xx"; do
        case $opt in
            "NVIDIA Optimus+TLP" ) sudo dnf install -y akmod-nvidia intel-media-driver libva-intel-driver mesa-dri-drivers.i686 tlp; break;;
            "NVIDIA 390xx" ) sudo dnf install -y akmod-nvidia-390xx xorg-x11-drv-nvidia-390xx; break;;
        esac
    done
}

pipinstall() {
    python3 -m pip install -U gallery-dl tartube youtube-dl
}

emulatorsinstall() {
    sudo flatpak install -y flathub "${flatemus[@]}"
}

vbox() {
    sudo dnf install -y VirtualBox
    sudo modprobe vboxdrv
}

wine() {
    sudo dnf config-manager --add-repo https://dl.winehq.org/wine-builds/fedora/$(rpm -E %fedora)/winehq.repo
    sudo dnf install -y cabextract winehq-devel
    $HOME/Arch-Stuff/scripts/winetricks.sh
    update_winetricks
    winetricks -q gdiplus vcrun2013 vcrun2015 wmp9
}

postinstall() {
    LINE='fastestmirror=1'
    FILE='/etc/dnf/dnf.conf'
    sudo grep -qF -- "$LINE" "$FILE" || echo "$LINE" | sudo tee -a "$FILE"
    
    sudo dnf remove -y akregator calligra-* dragon kaddressbook kamoso kcalc kdeconnect kf5-ktnef kget kmahjongg kmail kmines kmouth kolourpaint konversation korganizer kpat kruler krusader ktorrent kwrite juk
    sudo dnf autoremove -y
    
    sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    sudo dnf upgrade -y
    
    sudo dnf install -y "${packages[@]}"
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    sudo flatpak install -y flathub "${flatpkgs[@]}"
    
    sudo dnf install -y $HOME/Programs/Packages/*.rpm
    
    sudo ln -sf $HOME/Arch-Stuff/postinst_fedora.sh /usr/local/bin/postinst
    sudo rm -rf /media
    sudo ln -sf /run/media /media
}

# ----------------------------------

clear
echo "LukeZGD Fedora Post-Install Script"
echo "This script will assume that you have a working Internet connection"
echo

MainMenu
