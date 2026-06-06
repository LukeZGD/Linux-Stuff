#!/bin/bash
trap "exit 1" INT TERM
. $HOME/Linux-Stuff/scripts/preparelutris.sh
. $HOME/Linux-Stuff/postinst_shared.sh
. /etc/os-release

packages=(
aria2
audacious
audacity
build-essential
clinfo
curl
default-jre
f3
fastfetch
filezilla
firmware-linux-nonfree
fish
flatpak
gimp
git
gstreamer1.0-plugins-bad
gstreamer1.0-plugins-base
gstreamer1.0-plugins-good
gstreamer1.0-plugins-ugly
hplip
intel-gpu-tools
intel-media-va-driver-non-free
intel-opencl-icd
libreoffice
mpv
network-manager-openvpn
pavucontrol
piper
pipx
python-is-python3
python3-pip
qdirstat
rar
samba
stress
transmission-gtk
ttf-mscorefonts-installer
unrar
xdelta3
)

postinst() {
    sudo apt update
    sudo apt upgrade -y
    sudo apt install -y "${packages[@]}"
    sudo apt autoremove -y
    sudo apt remove -y gnome-software gnome-text-editor loupe yt-dlp
    gsettings set org.gnome.desktop.sound allow-volume-above-100-percent 'true'

    sudo chown -R $USER: /usr/local
    ln -sf $HOME/Linux-Stuff/postinst_debian.sh /usr/local/bin/postinst
    printf '#!/bin/sh\nsystemctl poweroff' > /usr/local/bin/poweroff
    printf '#!/bin/sh\nsystemctl reboot' > /usr/local/bin/reboot
    chmod +x /usr/local/bin/*
    if [[ ! $(ls /mnt/Data) ]]; then
        sudo mkdir /mnt/Data
        sudo chown $USER: /mnt/Data
    fi

    flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    flatpak install -y flathub "${flatpkgs[@]}"
}

sambainstall() {
    sudo cp /usr/share/samba/smb.conf /etc/samba/smb.conf
    sudo sed -i '/them./{n;s/.*/read only = no\nfollow symlinks = yes\nwide links = yes\nacl allow execute always = yes/}' /etc/samba/smb.conf
    sudo sed -i '/\[global\]/{n;s/.*/allow insecure wide links = yes/}' /etc/samba/smb.conf
    sudo smbpasswd -a $USER
}

emulatorsinst() {
    #sudo apt install -y nestopia
    flatpakemusinst
}

kvm() {
    sudo apt install qemu-system-x86 qemu-utils libvirt-daemon-system libvirt-clients bridge-utils virt-manager ovmf
    sudo usermod -aG kvm,libvirt $USER
    echo 'SUBSYSTEM=="vfio", OWNER="root", GROUP="kvm"' | sudo tee /etc/udev/rules.d/10-qemu.rules
    echo "add 'iommu=pt intel-iommu=on' (or amd-iommu) to /etc/default/grub then press enter"
    read -s
    sudo update-grub
}

main() {
    select opt in "Install stuff" "Run postinstall commands" "Backup and restore"; do
    case $opt in
        "Install stuff" ) installstuff; break;;
        "Run postinstall commands" ) postinst; break;;
        "pip install/update" ) pipinst; break;;
        "backup and restore" ) $HOME/Linux-Stuff/postinst.sh BackupRestore; break;;
    esac
    done
}

installstuff() {
    select opt in "wine prefixes" "osu!" "Emulators" "samba" "VBox Extension Pack" "KVM w/ virt-manager" "HSR"; do
    case $opt in
        "wine prefixes" ) wineprefixes; break;;
        "osu!" ) $HOME/Linux-Stuff/scripts/osu.sh install; break;;
        "Emulators" ) flatpakemusinst; break;;
        "VBox Extension Pack" ) vboxextension; break;;
        "KVM w/ virt-manager" ) kvm; break;;
        "samba" ) sambainstall; break;;
        "HSR" ) hsr; break;;
        * ) exit;;
    esac
    done
}

if [[ $(groups | grep -c 'sudo') == 0 ]]; then
    echo "$USER is not in sudo group. add $USER to sudo first:"
    echo "    su -"
    echo "    <enter root pass>"
    echo "    usermod -aG sudo $USER"
    echo "    systemctl reboot"
    exit 1
fi

if [[ $1 == "update" ]]; then
    sudo apt update
    sudo apt upgrade -y
    pipinst
    flatpak update -y
    exit
fi

main
