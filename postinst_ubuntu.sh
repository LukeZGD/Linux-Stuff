#!/bin/bash

packages=(
ark
ffmpegthumbs
gimp
k3b
kamoso
kate
kde-spectacle
kdenlive
kdialog
kfind
kolourpaint
ksysguard
mpv
qsynth

gnome-calculator
gnome-disk-utility
gparted
libreoffice
okteta
okular
okular-extra-backends
qbittorrent
qdirstat
simple-scan
tlpui

cups-pdf
curl
f3
fish
flatpak
git
htop
imagemagick
intel-gpu-tools
neofetch
openjdk-11-jre
pavucontrol-qt
plasma-discover-backend-flatpak
plasma-nm
printer-driver-gutenprint
python-is-python3
python3-pip
rar
samba
unrar
v4l2loopback-dkms
webp
xdelta3
zenity
zsync

network-manager-openvpn
openvpn
resolvconf

audacious
audacious-plugins
obs-studio
persepolis

libgl1-mesa-glx
libgl1-mesa-dri
libgl1-mesa-glx:i386
libgl1-mesa-dri:i386
libjsoncpp24
libqt5websockets5
libsdl2-net-2.0-0
)

flatpkgs=(
org.audacityteam.Audacity
org.gtk.Gtk3theme.Breeze
)

flatemus=(
io.mgba.mGBA
org.DolphinEmu.dolphin-emu
org.ppsspp.PPSSPP
)

. /etc/os-release

MainMenu() {
    select opt in "Install stuff" "Run postinstall commands" "pip install/update" "Backup and restore" "NVIDIA" "(Re-)Add PPAs"; do
        case $opt in
            "Install stuff" ) installstuff; break;;
            "Run postinstall commands" ) postinstall; break;;
            "pip install/update" ) pip3 install -U gallery-dl tartube youtube-dl; break;;
            "Backup and restore" ) $HOME/Arch-Stuff/postinst.sh BackupRestore; break;;
            "NVIDIA" ) nvidia; break;;
            "(Re-)Add PPAs" ) AddPPAs; break;;
            * ) exit;;
        esac
    done
}

installstuff() {
    select opt in "VirtualBox" "wine" "osu!" "Emulators" "system76-power" "OpenTabletDriver" "Intel non-free"; do
        case $opt in
            "VirtualBox" ) vbox; break;;
            "wine" ) wineinstall; break;;
            "osu!" ) $HOME/Arch-Stuff/scripts/osu.sh install; break;;
            "Emulators" ) sudo apt install nestopia pcsx2; sudo flatpak install flathub "${flatemus[@]}"; break;;
            "system76-power" ) system76power; break;;
            "OpenTabletDriver" ) opentabletdriver; break;;
            "Intel non-free" ) sudo apt install i965-va-driver-shaders intel-media-va-driver-non-free; break;;
            "KVM" ) KVM; break;;
            * ) exit;;
        esac
    done
}

KVM() {
    sudo apt install qemu-kvm qemu-utils libvirt-daemon-system libvirt-clients bridge-utils virt-manager ovmf
    sudo usermod -aG kvm,libvirt $USER
    echo 'SUBSYSTEM=="vfio", OWNER="root", GROUP="kvm"' | sudo tee /etc/udev/rules.d/10-qemu.rules
    echo "add 'iommu=pt intel-iommu=on' (or amd-iommu) to /etc/default/grub' then press enter"
    read -s
    sudo update-grub
}

AddPPAs() {
    #sudo add-apt-repository -y ppa:alexlarsson/flatpak
    #sudo add-apt-repository -y ppa:jurplel/qview
    #sudo add-apt-repository -y ppa:libreoffice/ppa
    #sudo add-apt-repository -y ppa:persepolis/ppa
    sudo add-apt-repository -y ppa:kubuntu-ppa/backports
    sudo add-apt-repository -y ppa:linuxuprising/apps
    sudo add-apt-repository -y ppa:obsproject/obs-studio
    sudo add-apt-repository -y ppa:ubuntuhandbook1/apps
    sudo apt update
    sudo apt full-upgrade -y
}

system76power() {
    sudo apt-add-repository -y ppa:system76-dev/stable
    sudo apt update
    sudo apt dist-upgrade -y
    sudo apt autoremove -y
    sudo apt install -y system76-power tlp
    sudo cp $HOME/Arch-Stuff/scripts/discrete /lib/systemd/system-sleep/
}

opentabletdriver() {
    mkdir tablet
    cd tablet
    wget https://packages.microsoft.com/config/ubuntu/$VERSION_ID/packages-microsoft-prod.deb
    wget https://github.com/OpenTabletDriver/OpenTabletDriver/releases/latest/download/OpenTabletDriver.deb
    sudo dpkg -i packages-microsoft-prod.deb
    sudo apt update
    sudo apt install -y apt-transport-https
    sudo apt install -y ./OpenTabletDriver.deb
    systemctl --user daemon-reload
    systemctl --user enable --now opentabletdriver
    cd ..
    rm -rf tablet
}

nvidia() {
    select opt in "NVIDIA 470" "NVIDIA 390"; do
        case $opt in
            "NVIDIA 470" ) sudo apt install -y --no-install-recommends nvidia-driver-470 nvidia-settings libnvidia-gl-470:i386 libnvidia-compute-470:i386 libnvidia-decode-470:i386 libnvidia-encode-470:i386 libnvidia-ifr1-470:i386 libnvidia-fbc1-470:i386; break;;
            "NVIDIA 390" ) sudo apt install -y nvidia-driver-390 libnvidia-gl-390:i386; break;;
        esac
    done
}

vbox() {
    sudo apt install -y virtualbox virtualbox-guest-additions-iso
    sudo usermod -aG vboxusers $USER
    sudo modprobe vboxdrv
    vboxversion=$(curl -L https://download.virtualbox.org/virtualbox/LATEST-STABLE.TXT)
    vboxextpack="Oracle_VM_VirtualBox_Extension_Pack-$vboxversion.vbox-extpack"
    wget https://www.virtualbox.org/download/hashes/$vboxversion/SHA256SUMS
    wget https://download.virtualbox.org/virtualbox/$vboxversion/$vboxextpack
    sha256sum -c --ignore-missing SHA256SUMS
    [[ $? != 0 ]] && echo "Failed" && rm $vboxextpack SHA256SUMS && exit
    sudo VBoxManage extpack install --replace $vboxextpack
    rm $vboxextpack SHA256SUMS
}

wineinstall() {
    wget -nc https://dl.winehq.org/wine-builds/winehq.key
    sudo apt-key add winehq.key
    rm winehq.key
    sudo add-apt-repository -y "deb https://dl.winehq.org/wine-builds/ubuntu/ $UBUNTU_CODENAME main"
    sudo apt update
    sudo apt install -y winehq-stable cabextract fuseiso libmspack0
    $HOME/Arch-Stuff/scripts/winetricks.sh
    update_winetricks
    winetricks -q dxvk gdiplus vcrun2013 vcrun2015 vcrun2019 wmp9
    cd $HOME/.wine/drive_c/users/$USER
    rm -rf AppData 'Application Data'
    ln -sf $HOME/AppData
    ln -sf $HOME/AppData 'Application Data'
}

postinstall() {
    sudo dpkg --add-architecture i386
    sudo apt purge -y eog evince file-roller geary gedit gwenview kcalc kdeconnect kwrite snapd totem vlc
    sudo apt autoremove -y

    AddPPAs
    
    sudo apt install -y "${packages[@]}"
    flatpak remote-delete flathub
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    sudo flatpak install -y flathub "${flatpkgs[@]}"
    sudo flatpak override org.audacityteam.Audacity --unshare=network

    sudo dpkg -i $HOME/Programs/Packages/*.deb
    sudo apt install -yf
    
    sudo ln -sf $HOME/Arch-Stuff/postinst_ubuntu.sh /usr/local/bin/postinst
    
    LINE='0.0.0.0 get.code-industry.net'
    FILE='/etc/hosts'
    sudo grep -qF -- "$LINE" "$FILE" || echo "$LINE" | sudo tee -a "$FILE"
    
    #echo "xmodmap -e 'keycode 79 = Q KP_7'" | tee -a $HOME/.profile
    #echo "xmodmap -e 'keycode 90 = space KP_0'" | tee -a $HOME/.profile
    
    sudo modprobe bfq
    echo 'ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
    ACTION=="add|change", KERNEL=="sd[a-z]|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"' | sudo tee /etc/udev/rules.d/60-ioschedulers.rules
    echo "vm.swappiness=10" | sudo tee /etc/sysctl.d/99-swappiness.conf
    sudo sed -i "s|GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash\"|GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash\"|g" /etc/default/grub
    sudo update-grub
    : "
    echo 'HandlePowerKey=suspend-then-hibernate
HandleLidSwitch=suspend-then-hibernate
HandleLidSwitchExternalPower=suspend-then-hibernate
HandleLidSwitchDocked=suspend-then-hibernate
IdleAction=suspend-then-hibernate
IdleActionSec=15min
HibernateDelaySec=10800' | sudo tee -a /etc/systemd/logind.conf
    "
    echo 'HandlePowerKey=suspend
HandleLidSwitch=suspend
HandleLidSwitchExternalPower=suspend
HandleLidSwitchDocked=suspend
IdleAction=suspend
IdleActionSec=15min' | sudo tee -a /etc/systemd/logind.conf
    sudo cp $HOME/Arch-Stuff/scripts/discrete /lib/systemd/system-sleep
    
    sudo sed -i "s|ExecStart=/usr/lib/bluetooth/bluetoothd|ExecStart=/usr/lib/bluetooth/bluetoothd --noplugin=avrcp|g" /etc/systemd/system/bluetooth.target.wants/bluetooth.service
    
    sudo cp /etc/samba/samba.conf /etc/samba/samba.conf.bak
    echo "[global]
    allow insecure wide links = yes
    workgroup = WORKGROUP
    netbios name = $(cat /etc/hostname)

    [LinuxHost]
    comment = Host Share
    path = $HOME
    valid users = $USER
    public = no
    writable = yes
    printable = no
    follow symlinks = yes
    wide links = yes" | sudo tee /etc/samba/smb.conf
    sudo smbpasswd -a $USER
    sudo systemctl enable --now nmbd smbd
    
    echo "v4l2loopback" | sudo tee /etc/modules-load.d/v4l2loopback.conf
    
    echo "[Log] swapfile"
    sudo dd if=/dev/zero of=/swapfile bs=1M count=4096 status=progress
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo "[Log] Edit /etc/fstab"
    echo "tmpfs	/tmp	tmpfs	defaults,noatime,mode=1777	0	0" | sudo tee -a /etc/fstab
    echo "/swapfile none swap defaults 0 0" | sudo tee -a /etc/fstab
    
    read -p "[Input] Enable hibernation? (y/N) " Hibernate
    [[ $Hibernate != y && $Hibernate != Y ]] && exit
    
    sudo apt install -y hibernate pm-utils
    swapuuid=$(findmnt -no UUID -T /swapfile)
    swapoffset=$(sudo filefrag -v /swapfile | awk '{ if($1=="0:"){print $4} }')
    swapoffset=$(echo ${swapoffset//./})
    echo "[Log] Edit /etc/default/grub"
    sudo sed -i "s|GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash\"|GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash resume=UUID=$swapuuid resume_offset=$swapoffset\"|g" /etc/default/grub
    echo "[Log] Run update-grub"
    sudo update-grub
    
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
    #xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/logind-handle-power-key -n -t bool -s true
    #xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/logind-handle-lid-switch -n -t bool -s true
    #xfconf-query -c xfwm4 -p /general/mousewheel_rollup -s false
}

# ----------------------------------

clear
echo "LukeZGD Ubuntu Post-Install Script"
echo "This script will assume that you have a working Internet connection"
echo

MainMenu
