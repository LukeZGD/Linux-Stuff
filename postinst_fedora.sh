#!/bin/bash
trap "exit 1" INT TERM EXIT
. $HOME/Linux-Stuff/scripts/preparelutris.sh
. $HOME/Linux-Stuff/postinst_shared.sh

packages=(
aria2
audacious
audacious-plugins-amidi
audacious-plugins-freeworld
audacity
cpu-x
dialog
'dnf-command(versionlock)'
f3
ffmpeg
ffmpegthumbs
fish
gdm
gimp
git
gnome-calculator
gnome-disk-utility
google-noto-sans-fonts
hplip
k3b
kate
kdenlive
ksysguard
mpv
neofetch
nodejs-npm
obs-studio
okteta
persepolis
piper
python3-pip
python3-wxpython4
radeontop
qdirstat
simple-scan
tealdeer
transmission-qt
unrar
VirtualBox
xdelta
yt-dlp
)

MainMenu() {
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

installstuff() {
    select opt in "wine prefixes" "osu!" "Emulators" "samba" "FL Studio" "Brother DCP-L2540DW" "Brother DCP-T720DW" "VBox Extension Pack" "KVM w/ virt-manager"; do
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
    flatpakemusinst ca._0ldsk00l.Nestopia
}

wineprefixes() {
    cd $HOME/.cache
    rm -rf wine winetricks
    ln -sf /mnt/Data/$USER/cache/wine
    ln -sf /mnt/Data/$USER/cache/winetricks

    winetricks --self-update
    preparewineprefix "$HOME/.wine"
    winetricks -q corefonts gdiplus mfc42 vcrun2010 vcrun2013 vcrun2019 vkd3d win10 wmp11
    WINEPREFIX=$HOME/.wine $HOME/Documents/mf-install/mf-install.sh

    preparelutris "$lutrisver"
    preparewineprefix "$HOME/.wine_lutris"
    WINEPREFIX=$HOME/.wine_lutris winetricks -q corefonts quartz vkd3d win10 wmp9

    preparewineprefix "$HOME/.wine_lutris-2"
    WINEPREFIX=$HOME/.wine_lutris-2 winetricks -q corefonts quartz vkd3d win10 wmp9

    preparelutris "$protonver" "proton"
    preparewineprefix "$HOME/.wine_proton"
    mkdir -p $WINEPREFIX/drive_c/users/steamuser
    cd $WINEPREFIX/drive_c/users/steamuser
    rm -rf 'Saved Games'
    ln -sf $HOME/AppData 'Saved Games'
}

postinst() {
    LINE='fastestmirror=True'
    FILE='/etc/dnf/dnf.conf'
    #sudo grep -qF -- "$LINE" "$FILE" || echo "$LINE" | sudo tee -a "$FILE"
    LINE='max_parallel_downloads=10'
    sudo grep -qF -- "$LINE" "$FILE" || echo "$LINE" | sudo tee -a "$FILE"
    
    sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    sudo dnf upgrade -y
    sudo dnf install -y --best --allowerasing ffmpeg-libs
    sudo dnf install -y "${packages[@]}"
    sudo dnf group install -y kde-desktop-environment
    sudo dnf remove -y akregator dragon elisa-player gwenview kaddressbook kcalc kf5-ktnef kmahjongg kmail kmouth konversation korganizer kpat
    sudo dnf reinstall -y $HOME/Programs/Packages/*.rpm
    sudo dnf autoremove -y
    #LINE='exclude=qview, xorg-x11-server-Xwayland'
    #sudo grep -qF -- "$LINE" "$FILE" || echo "$LINE" | sudo tee -a "$FILE"
    sudo dnf versionlock add qview xorg-x11-server-Xwayland

    echo 'KWIN_DRM_NO_AMS=1' | sudo tee /etc/environment
    sudo systemctl disable firewalld sddm
    sudo systemctl enable gdm
    sudo usermod -aG vboxusers $USER
    sudo ln -sf /usr/lib64/libbz2.so.1.0.8 /usr/lib64/libbz2.so.1.0
    sudo chown -R $USER: /usr/local
    ln -sf $HOME/Linux-Stuff/postinst_fedora.sh /usr/local/bin/postinst
    printf '#!/bin/sh\n/usr/bin/yt-dlp --compat-options youtube-dl "$@"' > /usr/local/bin/youtube-dl
    chmod +x /usr/local/bin/youtube-dl
    sudo rm -rf /media
    sudo ln -sf /run/media /media
    if [[ ! $(ls /mnt/Data) ]]; then
        sudo mkdir -p /mnt/Data
        sudo chown $USER: /mnt/Data
    fi

    sudo dnf config-manager --add-repo https://dl.winehq.org/wine-builds/fedora/$(rpm -E %fedora)/winehq.repo
    sudo dnf install -y cabextract lutris winehq-staging

    pipinst

    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    sudo flatpak override --filesystem=xdg-config/gtk-3.0
    sudo flatpak override --filesystem=xdg-config/gtk-4.0
    flatpak install -y flathub "${flatpkgs[@]}"
    export LINE='enableWaylandShare=true'
    export FILE='/home/lukee/.var/app/us.zoom.Zoom/config/zoomus.conf'
    grep -qF -- "$LINE" "$FILE" || echo "$LINE" | tee -a "$FILE"
}

# ----------------------------------

clear
echo "LukeZGD Fedora Post-Install Script"
echo "This script will assume that you have a working Internet connection"
echo

if [[ $1 == "update" ]]; then
    sudo dnf update -y
    pipinst
    flatpak update -y
    exit
fi

MainMenu
