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
neofetch
network-manager-openvpn
obs-studio
okteta
openjdk-8-jre
openvpn
qbittorrent
qdirstat
resolvconf
samba
simple-scan
winetricks
)

flatpkgs=(
com.interversehq.qView
com.wps.Office
us.zoom.Zoom
)

flatemus=(
io.mgba.mGBA
net.kuribo64.melonDS
net.pcsx2.PCSX2
org.DolphinEmu.dolphin-emu
org.ppsspp.PPSSPP
)

function MainMenu {
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

function installstuff {
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

function nvidia {
    select opt in "NVIDIA Optimus+TLP" "NVIDIA 390xx"; do
        case $opt in
            "NVIDIA Optimus+TLP" ) sudo apt install -y nvidia-driver-450 libnvidia-gl-450:i386 libgl1-mesa-glx libgl1-mesa-dri libgl1-mesa-glx:i386 libgl1-mesa-dri:i386 tlp; break;;
            "NVIDIA 390xx" ) sudo apt install -y nvidia-driver-390 libnvidia-gl-390:i386; break;;
        esac
    done
}

function pipinstall {
    sudo apt install -y python3-pip
    python3 -m pip install -U gallery-dl tartube youtube-dl
}

function emulatorsinstall {
    flatpak install -y flathub ${flatemus[*]}
    sudo apt install -y mednafen
}

function vbox {
    sudo apt install -y virtualbox virtualbox-ext-pack virtualbox-guest-additions-iso
    sudo usermod -aG vboxusers $USER
    sudo modprobe vboxdrv
}

function wine {
    wget -nc https://dl.winehq.org/wine-builds/winehq.key
    sudo apt-key add winehq.key
    rm winehq.key
    sudo add-apt-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ focal main' 
    sudo apt update
    sudo apt install -y --install-recommends winehq-stable
    winetricks -q gdiplus vcrun2013 vcrun2015 wmp9
}

function postinstall {
    sudo dpkg --add-architecture i386
    sudo apt purge -y gwenview kdeconnect kwrite snapd vlc
    sudo apt autoremove -y

    sudo add-apt-repository -y ppa:obsproject/obs-studio
    sudo add-apt-repository -y ppa:ubuntuhandbook1/apps
    sudo apt update
    sudo apt dist-upgrade -y
    
    sudo apt install -y ${packages[*]}
    sudo apt install -y --no-install-recommends mpv
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    flatpak install -y flathub ${flatpkgs[*]}
    
    sudo dpkg -i $HOME/Documents/Packages/*.deb
    sudo apt install -yf
    
    sudo ln -sf $HOME/Arch-Stuff/postinst_ubuntu.sh /usr/local/bin/postinst
    
    sudo apt install -y hibernate pm-utils
    clear
    lsblk
    read -p "[Input] Please enter swap partition (/dev/sdaX) " swappart
    swapuuid=$(blkid -o value -s UUID $swappart)
    echo "[Log] Got UUID of swap $swappart: $swapuuid"
    echo "[Log] Edit /etc/default/grub"
    sudo sed -i "s|GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash\"|GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash resume=UUID=$swapuuid\"|g" /etc/default/grub
    echo "[Log] Run grub-mkconfig"
    sudo grub-mkconfig -o /boot/grub/grub.cfg
    
    sudo modprobe bfq
    echo 'ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
    ACTION=="add|change", KERNEL=="sd[a-z]|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"' | sudo tee /etc/udev/rules.d/60-ioschedulers.rules
    echo "vm.swappiness=10" | sudo tee /etc/sysctl.d/99-swappiness.conf
    
    sudo bash -c 'cat > /etc/polkit-1/localauthority/50-local.d/com.ubuntu.enable-hibernate.pkla << EOF
[Re-enable hibernate by default in upower]
Identity=unix-user:*
Action=org.freedesktop.upower.hibernate
ResultActive=yes

[Re-enable hibernate by default in logind]
Identity=unix-user:*
Action=org.freedesktop.login1.hibernate;org.freedesktop.login1.handle-hibernate-key;org.freedesktop.login1;org.freedesktop.login1.hibernate-multiple-sessions;org.freedesktop.login1.hibernate-ignore-inhibit
ResultActive=yes
EOF'
}

# ----------------------------------

clear
echo "LukeZGD Ubuntu Post-Install Script"
echo "This script will assume that you have a working Internet connection"
echo

MainMenu
