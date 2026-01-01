#!/bin/bash
trap "exit 1" INT TERM
WORKDIR="$HOME/Documents/GitHub/Linux-Stuff"
. $WORKDIR/scripts/preparelutris.sh
. $WORKDIR/postinst_shared.sh

packages=(
aria2
audacious
audacious-plugins-amidi
audacious-plugins-freeworld
audacity
corectrl
dialog
f3
fastfetch
file-roller
fish
fuse
fuse-libs
gh
ghex
gimp
git
gnome-tweaks
guvcview
mangohud
mpv
nodejs-npm
obs-studio
p7zip
p7zip-plugins
piper
pipx
qdirstat
qview
shellcheck
stress
tealdeer
transmission-gtk
unrar
xdelta
yt-dlp
)

main() {
    select opt in "Install stuff" "Run postinstall commands" "Backup and restore"; do
    case $opt in
        "Install stuff" ) installstuff; break;;
        "Run postinstall commands" ) postinst; break;;
        "pip install/update" ) pipinst; break;;
        "Backup and restore" ) $WORKDIR/postinst.sh BackupRestore; break;;
        * ) exit;;
    esac
    done
}

coprpkgs() {
    sudo dnf copr enable nucleo/linssid -y
    sudo dnf copr enable rok/cdemu -y
    sudo dnf install -y libmirage vhba kmod-vhba akmod-vhba dkms cdemu-daemon gcdemu openssl mokutil kernel-devel linssid-ex
}

installstuff() {
    select opt in "wine prefixes" "Emulators" "samba" "VBox Extension Pack" "KVM w/ virt-manager" "copr packages" "libinput-config"; do
    case $opt in
        "wine prefixes" ) wineprefixes; break;;
        "Emulators" ) flatpakemusinst; break;;
        "samba" ) sambainstall; break;;
        "VBox Extension Pack" ) vboxextension; break;;
        "KVM w/ virt-manager" ) kvm; break;;
        "copr packages" ) coprpkgs; break;;
        "libinput-config" ) libinput_config; break;;
        * ) exit;;
    esac
    done
}

kvm() {
    sudo dnf install -y bridge-utils libvirt virt-install qemu-kvm libvirt-devel virt-top libguestfs-tools guestfs-tools virt-manager
    sudo usermod -aG kvm,libvirt $USER
    #echo 'options kvm_amd nested=1' | sudo tee /etc/modprobe.d/kvm.conf
    echo 'add "iommu=pt" and "amd_iommu=on" or "intel_iommu=on" to GRUB_CMDLINE_LINUX in /etc/default/grub'
    echo 'optionally add: "pcie_acs_override=downstream,multifunction"'
    echo "then run: sudo bash -c 'grub2-mkconfig -o \"\$(readlink -e /etc/grub2.cfg)\"'"
}

sambainstall() {
    sudo dnf install -y samba
    sudo mv /etc/samba/smb.conf /etc/samba/smb.conf.bak
    sudo cp /etc/samba/smb.conf.example /etc/samba/smb.conf
    sudo setsebool -P samba_enable_home_dirs=on use_samba_home_dirs=on samba_export_all_rw=on
    sudo sed -i 's|writable = yes|writable = yes\n\tfollow symlinks = yes\n\twide links = yes\n\tacl allow execute always = True|g' /etc/samba/smb.conf
    sudo sed -i 's|workgroup = MYGROUP|workgroup = MYGROUP\n\tallow insecure wide links = yes|g' /etc/samba/smb.conf
    sudo smbpasswd -a $USER
}

postinst() {
    echo '[main]
fastestmirror=true
max_parallel_downloads=10' | sudo tee /etc/dnf/libdnf5.conf.d/80-local.conf
    sudo rm -rf /media
    sudo ln -sf /run/media /media
    if [[ ! $(ls /mnt/Data) ]]; then
        sudo mkdir -p /mnt/Data
    fi
    sudo chown $USER: /mnt/Data
    sudo chmod 755 /mnt/Data
    sudo chown -R $USER: /usr/local
    ln -sf $WORKDIR/postinst_fedora.sh /usr/local/bin/postinst

    # from https://github.com/wz790/Fedora-Noble-Setup
    rpmfusion_setup
    sudo dnf update -y
    flathub_setup
    graphics_drivers
    media_stuff
    microsoft_fonts

    sudo dnf install -y "${packages[@]}"
    sudo dnf remove -y gamemode gnome-text-editor
    sudo dnf group install -y c-development
    gsettings set org.gnome.desktop.sound allow-volume-above-100-percent 'true'
    #sudo usermod -aG vboxusers $USER

    flatpak install -y "${flatpkgs[@]}"
}

rpmfusion_setup() {
    # Get the free repository (most stuff you need)
    sudo dnf install -y \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm

    # Get the nonfree repository (NVIDIA drivers, some codecs)
    sudo dnf install -y \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

    # Update everything so it all plays nice together
    sudo dnf group upgrade core -y
    sudo dnf check-update
}

flathub_setup() {
    # Remove the limited Fedora repo
    flatpak remote-delete fedora

    # Add the real Flathub
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

    # Update everything
    flatpak update --appstream
}

graphics_drivers() {
    # Basic drivers and Vulkan support
    sudo dnf install -y mesa-dri-drivers mesa-vulkan-drivers vulkan-loader mesa-libGLU

    # AMD video acceleration (makes videos smoother)
    sudo dnf install -y mesa-va-drivers-freeworld mesa-vdpau-drivers-freeworld

    # Intel video acceleration (for newer Intel GPUs)
    sudo dnf install -y intel-media-driver
}

media_stuff() {
    # Replace the neutered ffmpeg with the real one
    sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing

    # Install all the GStreamer plugins
    sudo dnf install -y gstreamer1-plugins-{bad-\*,good-\*,base} \
        gstreamer1-plugin-openh264 gstreamer1-libav lame\* \
        --exclude=gstreamer1-plugins-bad-free-devel,gstreamer1-plugins-bad-free-opencv

    sudo dnf install -y --setopt=install_weak_deps=False gstreamer1-plugins-bad-free-opencv

    # Install multimedia groups
    sudo dnf group install -y multimedia
    sudo dnf group install -y sound-and-video

    # Install VA-API stuff
    sudo dnf install -y ffmpeg-libs libva libva-utils

    # Install the Cisco codec (it's free but weird licensing)
    sudo dnf install -y openh264 gstreamer1-plugin-openh264 mozilla-openh264

    # Enable the Cisco repo
    sudo dnf config-manager --set-enabled fedora-cisco-openh264
    sudo dnf update -y
}

microsoft_fonts() {
    # Install dependencies
    sudo dnf install -y curl cabextract xorg-x11-font-utils fontconfig

    # Install the fonts
    sudo rpm -i --nodigest --nosignature https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm

    # Update font cache
    sudo fc-cache -fv
}

firmware_update() {
    # See what can be updated
    sudo fwupdmgr get-devices

    # Refresh the firmware database
    sudo fwupdmgr refresh --force

    # Check for updates
    sudo fwupdmgr get-updates

    # Apply them
    sudo fwupdmgr update
}

libinput_config() {
    sudo dnf builddep -y libinput
    sudo dnf install -y libinput-devel
    git clone https://gitlab.com/warningnonpotablewater/libinput-config.git
    pushd libinput-config
    meson build
    pushd build
    ninja
    sudo ninja install
    echo 'scroll-factor=0.5' | sudo tee /etc/libinput.conf
    popd
    popd
}

# ----------------------------------

if [[ $1 == "update" ]]; then
    sudo dnf -y "$@"
    flatpak update -y
    exit
fi

main
