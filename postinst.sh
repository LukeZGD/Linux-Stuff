#!/bin/bash
trap "exit 1" INT TERM EXIT
BASEDIR="$(dirname $(type -p $0))"
. $HOME/Arch-Stuff/scripts/preparelutris.sh

packages=(
authy
cpu-x
downgrade
earlyoom
f3
gallery-dl
github-desktop
glfw-x11
kde-cdemu-manager
legendary
masterpdfeditor-free
mystiq
ndstrim
nohang-git
ocs-url
puddletag
qdirstat
qsynth
rustdesk-bin
vhba-module-dkms
wine-staging
yt-dlp
yt-dlp-drop-in
yt-dlg
zoom
)

MainMenu() {
    select opt in "Install stuff" "Run postinstall commands" "Backup and restore" "Add user" "NVIDIA"; do
    case $opt in
        "Install stuff" ) installstuff; break;;
        "Run postinstall commands" ) postinstallcomm; break;;
        "Backup and restore" ) BackupRestore; break;;
        "Add user" ) adduser; break;;
        "NVIDIA" ) nvidia; break;;
    * ) exit;;
    esac
    done
}

installstuff() {
    select opt in "Install AUR pkgs paru" "VirtualBox+Docker" "osu!" "Emulators" "Plymouth" "OpenTabletDriver" "KVM w/ virt-manager" "VMware" "MS office" "FL Studio" "Brother DCP-L2540DW" "Brother DCP-T720DW" "JP Input" "Chaotic AUR" "Waydroid" "auto-cpufreq"; do
    case $opt in
        "Install AUR pkgs paru" ) postinstall; break;;
        "VirtualBox+Docker" ) vbox; break;;
        "osu!" ) $HOME/Arch-Stuff/scripts/osu.sh install; break;;
        "Emulators" ) emulators; break;;
        "KVM w/ virt-manager" ) kvm; break;;
        "Plymouth" ) Plymouth; break;;
        "VMware" ) vmware; break;;
        "OpenTabletDriver" ) opentabletdriver; break;;
        "MS office" ) msoffice; break;;
        "FL Studio" ) $HOME/Arch-Stuff/scripts/flstudio.sh install; break;;
        "Brother DCP-L2540DW" ) brother_dcpl2540dw; break;;
        "Brother DCP-T720DW" ) brother_dcpt720dw; break;;
        "JP Input" ) jpmozc; break;;
        "Chaotic AUR" ) chaoticaur; break;;
        "Waydroid" ) waydroid; break;;
        "auto-cpufreq" ) autocpufreq; break;;
        * ) exit;;
    esac
    done
}

autocpufreq() {
    pac install auto-cpufreq
    sudo systemctl enable --now auto-cpufreq
}

kvm() {
    pac install virt-manager qemu-base qemu-ui-gtk vde2 dnsmasq bridge-utils openbsd-netcat
    sudo systemctl enable --now libvirtd
    sudo usermod -aG kvm,libvirt $USER
    #echo 'options kvm_amd nested=1' | sudo tee /etc/modprobe.d/kvm.conf
    echo 'add "iommu=pt" and "amd_iommu=on" or "intel_iommu=on" to /boot/loader/entries/arch.conf'
    echo 'optionally add: "pcie_acs_override=downstream,multifunction"'
    echo 'for endeavouros add kernel params to /etc/kernel/cmdline'
}

waydroid() {
    pac install lzip waydroid-image-gapps weston waydroid python-gbinder python-tqdm libgbinder lxc cython nftables dnsmasq sqlite
    sudo waydroid init -s GAPPS -f
    # https://github.com/casualsnek/waydroid_script
    cd $HOME/Documents/GitHub/waydroid_script
    git pull
    sudo python3 -m pip install -r requirements.txt
    sudo python3 main.py -n
    echo "start waydroid:
    weston (if on x-session)
    sudo systemctl start waydroid-container
    export XDG_SESSION_TYPE='wayland'; export DISPLAY=':1'; waydroid show-full-ui"
}

jpmozc() {
    pac install fcitx5-im fcitx5-mozc kcm-fcitx5
    if [[ $(cat /etc/environment | grep -c 'GTK_IM_MODULE=fcitx' == 0) ]]; then
        printf "\nGTK_IM_MODULE=fcitx\nQT_IM_MODULE=fcitx\nXMODIFIERS=@im=fcitx" | sudo tee -a /etc/environment
    fi
    cp /etc/xdg/autostart/org.fcitx.Fcitx5.desktop $HOME/.config/autostart
}

brother_dcpl2540dw() {
    read -p "[Input] IP Address of printer: " ip
    pac install brother-dcpl2540dw-cups brscan4
    sudo brsaneconfig4 -a name="DCP-L2540DW" model="DCP-L2540DW" ip=$ip
}

brother_dcpt720dw() {
    #read -p "[Input] IP Address of printer: " ip
    sudo pacman -U --noconfirm $HOME/Programs/Packages/dcpt720dwpdrv-3.5.0-1-x86_64.pkg.tar.zst
    pac install brscan4 brscan5
    #sudo brsaneconfig4 -a name="DCP-T720DW" model="DCP-T720DW" ip=$ip
    if [[ ! $(cat /etc/sane.d/dll.conf | grep "brother5") ]]; then
        echo "brother5" | sudo tee -a /etc/sane.d/dll.conf
    fi
}

msoffice() {
    WINEPREFIX=$HOME/.wine_office2010 WINEARCH=win32 winetricks winxp
    WINEPREFIX=$HOME/.wine_office2010 winetricks -q msxml6 riched20 gdiplus richtx32
    WINEPREFIX=$HOME/.wine_office2010 wine reg add 'HKEY_CURRENT_USER\Control Panel\Desktop' /t REG_DWORD /v LogPixels /d 144 /f
    echo "prepared wineprefix"
    echo "now run: WINEPREFIX=~/.wine_office2010 WINEARCH=win32 wine /path/to/setup.exe"
    echo "also add the kwinrule"
}

chaoticaur() {
    sudo pacman-key --recv-key FBA220DFC880C036 --keyserver keyserver.ubuntu.com
    sudo pacman-key --lsign-key FBA220DFC880C036
    sudo pacman -U --noconfirm --needed 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
    if [[ $(cat /etc/pacman.conf | grep -c chaotic) == 0 ]]; then
        printf "[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n" | sudo tee -a /etc/pacman.conf
    fi
    pac update
    pac install lib32-libffmpeg lib32-libmpeg2
    #pac install lib32-gst-libav
}

emulators() {
    pac install dolphin-emu duckstation-qt-bin fceux melonds-bin mgba-qt pcsx2-latest-bin ppsspp rmg rpcs3-bin rpcs3-udev ryujinx-bin snes9x-gtk
}

installpac() {
    git clone https://aur.archlinux.org/$1.git
    cd $1
    makepkg -sic --noconfirm
    cd ..
    rm -rf $1
}

postinstall() {
    cd $HOME/.cache
    ln -sf /mnt/Data/$USER/cache/paru
    sudo chown -R $USER: /usr/local
    ln -sf $HOME/Arch-Stuff/postinst.sh /usr/local/bin/postinst
    ln -sf $HOME/Arch-Stuff/scripts/pac.sh /usr/local/bin/pac

    echo "keyserver keyserver.ubuntu.com" | tee $HOME/.gnupg/gpg.conf
    chaoticaur
    pac install "${packages[@]}"
    pac install npm persepolis
    for pkg in $HOME/Programs/Packages/*.tar.zst; do sudo pacman -U --noconfirm --needed $pkg; done
    sudo systemctl enable --now nohang-desktop
}

postinstallcomm() {
    balooctl disable
    setxkbmap -layout us
    cd $HOME/.cache
    rm -rf paru wine winetricks
    ln -sf /mnt/Data/$USER/cache/paru
    ln -sf /mnt/Data/$USER/cache/wine
    ln -sf /mnt/Data/$USER/cache/winetricks
    cd $BASEDIR

    sudo chown -R $USER: /usr/local
    ln -sf $HOME/Arch-Stuff/postinst.sh /usr/local/bin/postinst
    ln -sf $HOME/Arch-Stuff/scripts/pac.sh /usr/local/bin/pac
    
    chaoticaur
    pac install lib32-gst-plugins-base lib32-gst-plugins-good lib32-libva-mesa-driver lib32-vulkan-icd-loader lib32-vulkan-intel lib32-vulkan-radeon lutris wine-staging winetricks
    #sudo winetricks --self-update
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

    rm -rf $HOME/.local/share/applications/wine*

    echo "[global]
    allow insecure wide links = yes
    workgroup = WORKGROUP
    netbios name = $(cat /etc/hostname)
    security = user
    printing = CUPS
    rpc_server:spoolss = external
    rpc_daemon:spoolssd = fork

    [printers]
    comment = All Printers
    path = /var/spool/samba
    browseable = yes
    guest ok = yes
    writable = no
    printable = yes
    create mode = 0700
    write list = root @adm @wheel $USER

    [print\$]
    comment = Printer Drivers
    path = /var/lib/samba/printers
    browseable = yes
    read only = yes
    guest ok = no

    [LinuxHost]
    comment = Host Share
    path = $HOME
    valid users = $USER
    public = no
    writable = yes
    force user = $USER
    printable = no
    follow symlinks = yes
    wide links = yes
    acl allow execute always = True" | sudo tee /etc/samba/smb.conf
    sudo smbpasswd -a $USER
    #sudo systemctl enable --now nmb smb
}

adduser() {
    read -p "[Input] Enter username: " username2
    echo "[Log] Creating user $username2"
    sudo useradd -m -g users -G audio,optical,storage $username2
    echo "[Log] Running passwd $username2"
    sudo passwd $username2
}

autocreate() {
    echo "[Desktop Entry]
    Type=Application
    Name=$1
    Comment=$1
    Exec=$2
    Icon=$3
    Categories=$4
    Encoding=UTF-8
    Terminal=false
    StartupNotify=false"
}

vbox() {
    pac install docker virtualbox virtualbox-ext-oracle virtualbox-guest-iso virtualbox-host-dkms
    sudo usermod -aG docker $USER
    sudo usermod -aG vboxusers $USER
    #sudo systemctl enable --now docker
}

nvidia() {
    select opt in "optimus" "latest" "470" "390" "disable"; do
    case $opt in
        '' ) return;;
        "disable" )
            echo '# Remove NVIDIA USB xHCI Host Controller devices, if present
            ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c0330", ATTR{power/control}="auto", ATTR{remove}="1"

            # Remove NVIDIA USB Type-C UCSI devices, if present
            ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c8000", ATTR{power/control}="auto", ATTR{remove}="1"

            # Remove NVIDIA Audio devices, if present
            ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", ATTR{power/control}="auto", ATTR{remove}="1"

            # Remove NVIDIA VGA/3D controller devices
            ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x03[0-9]*", ATTR{power/control}="auto", ATTR{remove}="1"' | sudo tee /etc/udev/rules.d/00-remove-nvidia.rules
            printf 'blacklist nouveau\noptions nouveau modeset=0' | sudo tee /etc/modprobe.d/blacklist-nouveau.conf
            return
        ;;
        "optimus" | "latest" ) pac install nvidia-dkms lib32-nvidia-utils nvidia-settings opencl-nvidia lib32-opencl-nvidia;;
        * ) nvidia4=$opt; pac install nvidia-${nvidia4}xx-dkms lib32-nvidia-${nvidia4}xx-utils nvidia-${nvidia4}xx-settings opencl-nvidia-${nvidia4}xx lib32-opencl-nvidia-${nvidia4}xx;;&
        "optimus" ) pac install bbswitch-dkms nvidia-prime optimus-manager optimus-manager-qt;;
    esac
    done
}

excludelist=(
".android"
".bash_history"
".bash_logout"
".cache"
".cargo"
".ccache"
".cemu"
".conan"
".config/Caprine"
".config/chromium/Default/File System"
".config/chromium/Default/Service Worker/CacheStorage"
".config/GitHub Desktop/Cache"
".config/google-chrome/Default/File System"
".config/google-chrome/Default/Service Worker/CacheStorage"
".darling"
".Genymobile/Genymotion/deployed"
".gitconfig"
".gradle"
".gtkrc-2.0"
".ld.so"
".local/share/baloo"
".local/share/flatpak"
".local/share/gvfs-metadata"
".local/share/Kingsoft"
".local/share/lutris/runners"
".local/share/NuGet"
".local/share/Steam"
".local/share/Trash"
".next"
".npm"
".nuget"
".nv"
".nvidia-settings-rc"
".nx"
".pam_environment"
".pipewire-media-session"
".profile"
".pyenv"
".rustup"
".steam"
".sudo_as_admin_successful"
".wine*"
".Xauthority"
".xsession-errors"
".zoom"
"Android"
"node_modules"
"Programs/Games"
"osu"
"VMs"
)

RSYNC() {
    [[ $ArgR != full && $ArgR != sparse ]] && Update=--update
    [[ $ArgR == full ]] && ArgR=
    rm /tmp/excludelist 2>/dev/null
    if [[ $3 == user ]]; then
        for exclude in "${excludelist[@]}"; do
            echo "$exclude" >> /tmp/excludelist
        done
        sudo rsync -va $ArgR $Update --del --info=progress2 --exclude-from=/tmp/excludelist $1 $2
    elif [[ $ArgR == sparse ]]; then
        [[ ! -d $2 ]] && ArgR="--ignore-existing --sparse" || ArgR="--existing --inplace"
        sudo rsync -va $ArgR --info=progress2 $1 $2
    else
        sudo rsync -va $ArgR $Update --del --info=progress2 --exclude "VirtualBox VMs" --exclude "wine" --exclude "files" $1 $2
    fi
}

BackupRestore() {
    HDDName="LukeHDDWDB"

    select opt in "Backup" "Restore"; do
    case $opt in
        "Backup" ) Action=Backup; break;;
        "Restore" ) Action=Restore; break;;
        * ) exit;;
    esac
    done
    select opt in "$Action home" "$Action pacman" "$Action VMs"; do
    case $opt in
        "$Action home" ) Mode=user; break;;
        "$Action pacman" ) Mode=pac; break;;
        "$Action VMs" ) ArgR=sparse; Mode=vm; break;;
        * ) exit;;
    esac
    done

    if [[ $Mode == user ]]; then
        Paths=("$HOME/" "/media/$USER/$HDDName/BackupsP/$USER/"
               "/mnt/Data/$USER/" "/media/$USER/$HDDName/BackupsP/Data/$USER/"
               "$HOME/osu/" "/media/$USER/$HDDName/BackupsP/Data/osu/")
    elif [[ $Mode == pac ]]; then
        Paths=("/var/cache/pacman/pkg/" "/media/$USER/$HDDName/BackupsP/pkg/"
               "/var/cache/pacman/aur/" "/media/$USER/$HDDName/BackupsP/aur/")
    elif [[ $Mode == vm ]]; then
        Paths=("$HOME/VMs/" "/media/$USER/$HDDName/BackupsP/Data/VMs/")
    fi

    if [[ $Action == Backup ]]; then
        if [[ $Mode == user ]]; then
            RSYNC ${Paths[0]} ${Paths[1]} user
            RSYNC ${Paths[2]} ${Paths[3]}
            RSYNC ${Paths[4]} ${Paths[5]}
        elif [[ $Mode == pac ]]; then
            RSYNC ${Paths[0]} ${Paths[1]}
            RSYNC ${Paths[2]} ${Paths[3]}
        elif [[ $Mode == vm ]]; then
            RSYNC ${Paths[0]} ${Paths[1]}
        fi
    elif [[ $Action == Restore ]]; then
        if [[ $Mode == user ]]; then
            select opt in "Update restore" "Full restore"; do
            case $opt in
                "Update restore" ) Restoreuser; break;;
                "Full restore" ) ArgR=full; Restoreuser; break;;
                * ) exit;;
            esac
            done
        elif [[ $Mode == pac ]]; then
            RSYNC ${Paths[1]} ${Paths[0]}
            RSYNC ${Paths[3]} ${Paths[2]}
        elif [[ $Mode == vm ]]; then
            RSYNC ${Paths[1]} ${Paths[0]}
        fi
    fi
}

Restoreuser() {
    RSYNC ${Paths[1]} ${Paths[0]} user
    RSYNC ${Paths[3]} ${Paths[2]}
    RSYNC ${Paths[5]} ${Paths[4]}
}

Plymouth() {
    sudo sed -i "s|HOOKS=(base udev autodetect modconf block keyboard encrypt lvm2 filesystems fsck)|HOOKS=(base udev plymouth plymouth-encrypt autodetect modconf block keyboard lvm2 filesystems fsck)|g" /etc/mkinitcpio.conf
    pac install plymouth
    sudo systemctl disable sddm
    sudo systemctl enable sddm-plymouth
}

vmware() {
    pac install vmware-workstation
    sudo modprobe -a vmw_vmci vmmon
    sudo systemctl enable --now vmware-networks vmware-usbarbitrator
    echo 'add mks.vk.allowUnsupportedDevices = "TRUE" in ~/.vmware/preferences'
}

opentabletdriver() {
    pac install dotnet-host dotnet-runtime dotnet-sdk opentabletdriver
    systemctl --user enable --now opentabletdriver
    #printf "blacklist wacom\nblacklist hid_uclogic\n" | sudo tee /etc/modprobe.d/blacklist.conf
}

# ----------------------------------

. /etc/os-release
clear
if [[ $ID == arch || $ID_LIKE == arch ]]; then
    echo "LukeZGD Arch Post-Install Script"
    echo "This script will assume that you have a working Internet connection"
    echo
    if [[ ! $(which paru) ]]; then
        echo "No paru detected, installing paru"
        installpac paru-bin
        sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
    fi
elif [[ $1 != BackupRestore ]]; then
    echo "WARNING: Not an Arch system!"
fi

if [[ $1 == BackupRestore ]]; then
    BackupRestore
else
    MainMenu
fi
