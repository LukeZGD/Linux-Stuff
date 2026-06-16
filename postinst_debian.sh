#!/bin/bash
trap "exit 1" INT TERM
WORKDIR="$HOME/Documents/GitHub/Linux-Stuff"
. $WORKDIR/scripts/preparelutris.sh
. $WORKDIR/postinst_shared.sh

packages=(
aria2
audacious
audacity
build-essential
clinfo
corectrl
curl
default-jre
dialog
f3
fastfetch
ffmpeg
ffmpegthumbnailer
firmware-linux-nonfree
fish
flatpak
fonts-noto-cjk
gh
ghex
gimp
git
gstreamer1.0-plugins-bad
gstreamer1.0-plugins-base
gstreamer1.0-plugins-good
gstreamer1.0-plugins-ugly
guvcview
intel-gpu-tools
intel-media-va-driver-non-free
linux-headers-$(uname -m)
mangohud
mpv
netselect-apt
network-manager-openvpn-gnome
p7zip
p7zip-full
pavucontrol
piper
pipx
python-is-python3
python3-pip
qdirstat
rar
rsync
samba
shellcheck
stress
transmission-gtk
ttf-mscorefonts-installer
unrar
xdelta3
)

postinst() {
    sudo sed -Ei '
    /^[[:space:]]*deb(-src)?[[:space:]]/ {
        /\bcontrib\b/! s/$/ contrib/
        /(^|[[:space:]])non-free([[:space:]]|$)/! s/$/ non-free/
    }
    ' "/etc/apt/sources.list"
    sudo apt update
    sudo apt upgrade -y
    sudo apt install -y "${packages[@]}"
    sudo apt remove -y evince firefox-esr gnome-software gnome-text-editor loupe totem yt-dlp
    sudo apt autoremove -y

    sudo apt purge -y "libreoffice*"
    sudo apt autoremove -y --purge

    gsettings set org.gnome.desktop.sound allow-volume-above-100-percent 'true'
    bashrc_custom
    disable_bluetooth_le
    echo 'ACTION=="add", SUBSYSTEM=="usb", DRIVERS=="usb", ATTR{power/wakeup}="disabled"' | sudo tee /etc/udev/rules.d/90-usb-wakeup.rules

    sudo chown -R $USER: /usr/local
    ln -sf $WORKDIR/postinst_debian.sh /usr/local/bin/postinst
    printf '#!/bin/sh\nsystemctl poweroff "$@"' > /usr/local/bin/poweroff
    printf '#!/bin/sh\nsystemctl reboot "$@"' > /usr/local/bin/reboot
    chmod +x /usr/local/bin/*
    if [[ ! $(ls /mnt/Data) ]]; then
        sudo mkdir /mnt/Data
        sudo chown $USER: /mnt/Data
    fi

    sudo sed -Ei 's/^[[:space:]]*GRUB_TIMEOUT=5$/GRUB_TIMEOUT=0/' "/etc/default/grub"
    sudo update-grub

    flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    flatpak install -y "${flatpkgs[@]}"
}

sambainstall() {
    sudo cp /usr/share/samba/smb.conf /etc/samba/smb.conf
    sudo sed -i '/them./{n;s/.*/read only = no\nfollow symlinks = yes\nwide links = yes\nacl allow execute always = yes/}' /etc/samba/smb.conf
    sudo sed -i '/\[global\]/{n;s/.*/allow insecure wide links = yes/}' /etc/samba/smb.conf
    sudo smbpasswd -a $USER
}

kvm() {
    sudo apt install qemu-system-x86 qemu-utils libvirt-daemon-system libvirt-clients bridge-utils virt-manager ovmf
    sudo usermod -aG kvm,libvirt $USER
    echo 'SUBSYSTEM=="vfio", OWNER="root", GROUP="kvm"' | sudo tee /etc/udev/rules.d/10-qemu.rules
    echo 'add "iommu=pt" and "amd_iommu=on" or "intel_iommu=on" to GRUB_CMDLINE_LINUX in /etc/default/grub'
    echo 'optionally add: "pcie_acs_override=downstream,multifunction"'
    echo "then run: sudo update-grub"
}

main() {
    select opt in "Install stuff" "Run postinstall commands" "pip install/update" "Backup and restore"; do
    case $opt in
        "Install stuff" ) installstuff; break;;
        "Run postinstall commands" ) postinst; break;;
        "pip install/update" ) pipinst; break;;
        "backup and restore" ) $WORKDIR/postinst.sh BackupRestore; break;;
    esac
    done
}

installstuff() {
    select opt in "Emulators" "HSR" "KVM w/ virt-manager" "samba" "VBox Extension Pack"; do
    case $opt in
        "Emulators" ) flatpakemusinst; break;;
        "HSR" ) hsr; break;;
        "KVM w/ virt-manager" ) kvm; break;;
        "samba" ) sambainstall; break;;
        "VBox Extension Pack" ) vboxextension; break;;
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
