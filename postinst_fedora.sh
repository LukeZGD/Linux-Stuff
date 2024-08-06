#!/bin/bash
trap "exit 1" INT TERM
. $HOME/Linux-Stuff/scripts/preparelutris.sh
. $HOME/Linux-Stuff/postinst_shared.sh

packages=(
aria2
audacious
audacious-plugins-amidi
audacious-plugins-freeworld
audacity
audiocd-kio
cpu-x
dialog
f3
fedora-repos-archive
ffmpeg
ffmpegthumbs
filezilla
fish
gamescope
gimp
git
gnome-calculator
gnome-disk-utility
google-noto-sans-fonts
hplip
igt-gpu-tools
intel-media-driver
k3b
kate
kdenlive
kio-fuse
mangohud
mpv
neofetch
nodejs-npm
obs-studio
okteta
persepolis
piper
python3-pip
python3-wxpython4
qdirstat
qview
shellcheck
simple-scan
stress
tealdeer
transmission-qt
unrar
VirtualBox
xdelta
yt-dlp
)

main() {
    select opt in "Install stuff" "Run postinstall commands" "pip install/update" "Backup and restore"; do
    case $opt in
        "Install stuff" ) installstuff; break;;
        "Run postinstall commands" ) postinst; break;;
        "pip install/update" ) pipinst; break;;
        "Backup and restore" ) $HOME/Linux-Stuff/postinst.sh BackupRestore; break;;
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
    select opt in "wine prefixes" "osu!" "Emulators" "samba" "FL Studio" "Brother DCP-L2540DW" "Brother DCP-T720DW" "VBox Extension Pack" "KVM w/ virt-manager" "copr packages" "HSR"; do
    case $opt in
        "wine prefixes" ) wineprefixes; break;;
        "osu!" ) $HOME/Linux-Stuff/scripts/osu.sh install; break;;
        "Emulators" ) emulatorsinst; break;;
        "samba" ) sambainstall; break;;
        "FL Studio" ) $HOME/Linux-Stuff/scripts/flstudio.sh install; break;;
        "Brother DCP-L2540DW" ) brother_dcpl2540dw; break;;
        "Brother DCP-T720DW" ) brother_dcpt720dw; break;;
        "VBox Extension Pack" ) vboxextension; break;;
        "KVM w/ virt-manager" ) kvm; break;;
        "copr packages" ) coprpkgs; break;;
        "HSR" ) hsr; break;;
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

brother_dcpl2540dw() {
    read -p "[Input] IP Address of printer: " ip
    sudo brsaneconfig4 -a name="DCP-L2540DW" model="DCP-L2540DW" ip=$ip
}

brother_dcpt720dw() {
    #read -p "[Input] IP Address of printer: " ip
    #sudo brsaneconfig4 -a name="DCP-T720DW" model="DCP-T720DW" ip=$ip
    if [[ ! $(cat /etc/sane.d/dll.conf | grep "brother5") ]]; then
        echo "brother5" | sudo tee -a /etc/sane.d/dll.conf
    fi
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

emulatorsinst() {
    #flatpakemusinst ca._0ldsk00l.Nestopia
    flatpakemusinst
}

postinst() {
    LINE='max_parallel_downloads=10'
    FILE='/etc/dnf/dnf.conf'
    sudo grep -qF -- "$LINE" "$FILE" || echo "$LINE" | sudo tee -a "$FILE"

    #sudo dnf install -y dnf5 dnf5-plugins
    sudo systemctl disable --now firewalld
    sudo chown -R $USER: /usr/local
    ln -sf $HOME/Linux-Stuff/postinst_fedora.sh /usr/local/bin/postinst
    #ln -sf /usr/bin/dnf5 /usr/local/bin/dnf
    sudo rm -rf /media
    sudo ln -sf /run/media /media
    if [[ ! $(ls /mnt/Data) ]]; then
        sudo mkdir -p /mnt/Data
        sudo chown $USER: /mnt/Data
    fi
    fc-cache -rv
    #echo "options snd-hda-intel power_save=0 power_save_controller=N" | sudo tee /etc/modprobe.d/audio-disable-powersave.conf

    sudo dnf group upgrade -y core
    sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    sudo dnf config-manager --enable fedora-cisco-openh264
    sudo dnf update -y --refresh
    sudo dnf install -y --best --allowerasing ffmpeg-libs
    sudo dnf install -y "${packages[@]}"

    sudo usermod -aG vboxusers $USER
    printf '#!/bin/sh\n/usr/bin/yt-dlp --compat-options youtube-dl "$@"' > /usr/local/bin/youtube-dl
    chmod +x /usr/local/bin/youtube-dl

    sudo dnf group install -y kde-desktop-environment
    sudo dnf remove -y akregator dragon elisa-player gwenview kaddressbook kcalc kf5-ktnef kmahjongg kmail kmouth konversation korganizer kpat
    sudo dnf install -y $HOME/Programs/Packages/rpm/*.rpm
    sudo dnf autoremove -y
    # winehq repo
    sudo dnf config-manager --add-repo https://dl.winehq.org/wine-builds/fedora/$(rpm -E %fedora)/winehq.repo
    # shiftkey repo
    sudo rpm --import https://rpm.packages.shiftkey.dev/gpg.key
    sudo sh -c 'echo -e "[shiftkey-packages]\nname=GitHub Desktop\nbaseurl=https://rpm.packages.shiftkey.dev/rpm/\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://rpm.packages.shiftkey.dev/gpg.key" > /etc/yum.repos.d/shiftkey-packages.repo'
    sudo dnf install -y cabextract lutris winehq-staging github-desktop gstreamer1-plugins-{good,ugly}.i686 gstreamer1-plugins-{good,ugly} gstreamer1-plugin-libav gstreamer1-plugin-libav.i686 hanazono-fonts mona-*-fonts langpacks-ja
    sudo dnf remove -y gamemode

    pipinst

    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    sudo flatpak override --filesystem=xdg-config/gtk-3.0
    sudo flatpak override --filesystem=xdg-config/gtk-4.0
    flatpak install -y flathub "${flatpkgs[@]}"
    LINE='enableWaylandShare=true'
    FILE='/home/lukee/.var/app/us.zoom.Zoom/config/zoomus.conf'
    grep -qF -- "$LINE" "$FILE" || echo "$LINE" | tee -a "$FILE"
}

# ----------------------------------

if [[ $1 == "update" ]]; then
    sudo dnf -y "$@"
    pipinst
    flatpak update -y
    exit
fi

main
