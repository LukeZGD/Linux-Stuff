#!/bin/bash
BASEDIR="$(dirname $(type -p $0))"

packages=(
earlyoom
f3
gallery-dl
github-desktop-bin
legendary
masterpdfeditor-free
mkmm
mystiq
nohang-git
portsmf-git
qdirstat
qsynth
qview
reflector-mirrorlist-update
shellcheck-bin
simplescreenrecorder
tenacity-git
ventoy-bin
waifu2x-ncnn-vulkan-bin
yt-dlp
yt-dlp-drop-in
youtube-dl-gui-git
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
    select opt in "Install AUR pkgs paru" "VirtualBox" "osu!" "Emulators" "Plymouth" "OpenTabletDriver" "KVM (with GVT-g)" "VMware Player install" "VMware Player update" "MS office" "FL Studio" "Chaotic AUR" "Linux Xanmod Kernel"; do
        case $opt in
            "Install AUR pkgs paru" ) postinstall; break;;
            "VirtualBox" ) vbox; break;;
            "osu!" ) $HOME/Arch-Stuff/scripts/osu.sh install; break;;
            "Emulators" ) emulators; break;;
            "KVM (with GVT-g)" ) kvm; break;;
            "Plymouth" ) Plymouth; break;;
            "VMware Player install" ) vmwarei; break;;
            "VMware Player update" ) vmwareu; break;;
            "OpenTabletDriver" ) opentabletdriver; break;;
            "MS office" ) msoffice; break;;
            "FL Studio" ) FL; break;;
            "Chaotic AUR" ) chaoticaur; break;;
            "Linux Xanmod Kernel" ) xanmod; break;;
            * ) exit;;
        esac
    done
}

msoffice() {
    WINEPREFIX=$HOME/.wine_office2010 WINEARCH=win32 winetricks winxp
    WINEPREFIX=$HOME/.wine_office2010 winetricks -q msxml6 riched20 gdiplus richtx32
    WINEPREFIX=$HOME/.wine_office2010 wine reg add 'HKEY_CURRENT_USER\Control Panel\Desktop' /t REG_DWORD /v LogPixels /d 120 /f
    echo "prepared wineprefix"
    echo "now run: WINEPREFIX=~/.wine_office2010 WINEARCH=win32 wine /path/to/setup.exe"
    echo "also add the kwinrule"
}

FL() {
    WINEPREFIX=$HOME/.wine_fl wine reg add 'HKEY_CURRENT_USER\Control Panel\Desktop' /t REG_DWORD /v LogPixels /d 144 /f
    cd "$HOME/.wine_fl/drive_c/Program Files/"
    ln -sf ../Program\ Files\ \(x86\)/Image-Line/ .
    mkdir "$HOME/.wine_fl/drive_c/users/$USER/Start Menu/Programs/Image-Line/"
    cp "$HOME/Documents/FL Studio 20 (32bit).lnk" "$HOME/.wine_fl/drive_c/users/$USER/Start Menu/Programs/Image-Line/"
    echo "prepared wineprefix"
    echo "now run: WINEPREFIX=~/.wine_fl /path/to/flsetup.exe"
}

chaoticaur() {
    sudo pacman-key --recv-key FBA220DFC880C036 --keyserver keyserver.ubuntu.com
    sudo pacman-key --lsign-key FBA220DFC880C036
    sudo pacman -U --noconfirm --needed 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
    printf "[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n" | sudo tee -a /etc/pacman.conf
}

xanmod() {
    pac remove linux-lts linux-lts-headers
    pac install linux-xanmod-lts linux-xanmod-lts-headers
    sudo sed -i "s/linux-lts/linux-xanmod-lts/g" /boot/loader/entries/arch.conf
    if [[ $(pac query nvidia-lts 2>/dev/null) ]]; then
        pac remove nvidia-lts
        pac install nvidia-dkms
        printf "blacklist nouveau\nblacklist nvidiafb\n" | sudo tee /etc/modprobe.d/my_nvidia.conf
    fi
}

emulators() {
    pac install cemu dolphin-emu libao melonds mgba-qt nestopia pcsx2 ppsspp rpcs3-udev snes9x-gtk
    WINEPREFIX=$HOME/.cemu/wine wine reg add 'HKEY_CURRENT_USER\Control Panel\Desktop' /t REG_DWORD /v LogPixels /d 144 /f
    WINEPREFIX=$HOME/.cemu/wine winetricks -q vcrun2017
    mkdir $HOME/.cemu
    cd $HOME/.cemu
    ln -s /usr/share/cemu/Cemu.exe .
    ln -s /usr/share/cemu/cemuhook.dll .
    ln -s /usr/share/cemu/keystone.dll .
    ln -s /usr/share/cemu/sharedFonts/ .
    ln -s /mnt/Data/$USER/cemu/controllerProfiles/ .
    ln -s /mnt/Data/$USER/cemu/graphicPacks/ .
    ln -s /mnt/Data/$USER/cemu/mlc01/ .
    ln -s /mnt/Data/$USER/cemu/settings.xml .
    ln -s /mnt/Data/$USER/cemu/shaderCache/ .
    cp -r /usr/share/cemu/gameProfiles/ .
    curl -L https://pastebin.com/raw/GWApZVLa -o keys.txt
}

installpac() {
    git clone https://aur.archlinux.org/$1.git
    cd $1
    makepkg -sic --noconfirm
    cd ..
    rm -rf $1
}

postinstall() {
    echo "keyserver keyserver.ubuntu.com" | tee $HOME/.gnupg/gpg.conf
    pac install "${packages[@]}"
    pac install persepolis
    sudo systemctl enable --now nohang-desktop
}

postinstallcomm() {
    sudo timedatectl set-ntp true
    sudo modprobe ohci_hcd
    setxkbmap -layout us
    sudo rm -rf /media
    sudo ln -sf /run/media /media
    cd $HOME/.local/share
    ln -sf /mnt/Data/$USER/share/citra-emu/
    ln -sf /mnt/Data/$USER/share/dolphin-emu/
    ln -sf /mnt/Data/$USER/share/osu/
    cd $HOME/.cache
    ln -sf /mnt/Data/$USER/cache/wine
    ln -sf /mnt/Data/$USER/cache/winetricks
    ln -sf /mnt/Data/$USER/cache/paru
    cd $BASEDIR

    sudo ln -sf $HOME/Arch-Stuff/postinst.sh /usr/local/bin/postinst
    sudo ln -sf $HOME/Arch-Stuff/scripts/pac.sh /usr/local/bin/pac
    
    pac install lib32-gst-plugins-base lib32-gst-plugins-good lib32-libva-intel-driver lib32-libva-mesa-driver lib32-vulkan-icd-loader lib32-vulkan-intel lib32-vulkan-radeon lutris wine-staging winetricks
    sudo winetricks --self-update
    winetricks -q gdiplus vcrun2010 vcrun2013 vcrun2019 wmp9
    $HOME/Documents/dxvk/setup_dxvk.sh install
    wine reg add 'HKEY_CURRENT_USER\Control Panel\Desktop' /t REG_DWORD /v LogPixels /d 120 /f
    wine reg add 'HKEY_CURRENT_USER\Software\Wine\DllOverrides' /t REG_SZ /v dsdmo /f
    cd $HOME/.wine/drive_c
    rm -rf ProgramData
    ln -sf $HOME/AppData ProgramData
    cd $HOME/.wine/drive_c/users/$USER
    rm -rf AppData 'Application Data'
    ln -sf $HOME/AppData
    ln -sf $HOME/AppData 'Application Data'
    
    sudo mkdir /var/cache/pacman/aur
    sudo chown $USER:users /var/cache/pacman/aur
    sudo sed -i "s|#PKGDEST=/home/packages|PKGDEST=/var/cache/pacman/aur|" /etc/makepkg.conf
    
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

    [print$]
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
    printable = no
    follow symlinks = yes
    wide links = yes" | sudo tee /etc/samba/smb.conf
    sudo smbpasswd -a $USER
    #sudo systemctl enable --now nmb smb
    
    echo "v4l2loopback" | sudo tee /etc/modules-load.d/v4l2loopback.conf
    sudo systemctl disable NetworkManager-wait-online
    sudo systemctl mask NetworkManager-wait-online
}

adduser() {
    read -p "[Input] Enter username: " username2
    echo "[Log] Creating user $username2"
    sudo useradd -m -g users -G audio,optical,storage -s /usr/bin/fish $username2
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
    pac install virtualbox virtualbox-ext-oracle virtualbox-guest-iso virtualbox-host-dkms
    sudo usermod -aG vboxusers $USER
    sudo modprobe vboxdrv
}

nvidia() {
    select opt in "NVIDIA Optimus+cpufreq" "NVIDIA Latest" "NVIDIA 470" "NVIDIA 390"; do
        case $opt in
            "NVIDIA Optimus+cpufreq" ) nvidia4=optimus; break;;
            "NVIDIA Latest" ) nvidia4=latest; break;;
            "NVIDIA 470" ) nvidia4=470; break;;
            "NVIDIA 390" ) nvidia4=390; break;;
            * ) exit;;
        esac
    done
    
    if [[ $nvidia4 == optimus || $nvidia4 == latest ]]; then
        pac install nvidia-lts lib32-nvidia-utils nvidia-settings opencl-nvidia lib32-opencl-nvidia
    elif [[ -n $nvidia4 ]]; then
        pac install nvidia-${nvidia4}xx-dkms lib32-nvidia-${nvidia4}xx-utils nvidia-${nvidia4}xx-settings opencl-nvidia-${nvidia4}xx lib32-opencl-nvidia-${nvidia4}xx
    fi
    
    if [[ $nvidia4 == optimus ]]; then
        pac install auto-cpufreq bbswitch-dkms nvidia-prime optimus-manager optimus-manager-qt
        sudo systemctl enable --now auto-cpufreq
    fi
}

kvm() {
    if [[ -e /sys/devices/pci0000:00/0000:00:02.0/mdev_supported_types && ! -e /etc/systemd/system/gvtvgpu.service ]]; then
        kvmstep2
    else
        kvmstep1
    fi
}

kvmstep1() {
    pac installc iptables-nft
    pac install virt-manager qemu vde2 ebtables dnsmasq bridge-utils openbsd-netcat
    sudo systemctl enable --now libvirtd
    #sudo sed -i "s|MODULES=(i915 ext4)|MODULES=(i915 ext4 kvmgt vfio vfio-iommu-type1)|g" /etc/mkinitcpio.conf
    sudo sed -i "s|MODULES=()|MODULES=(kvmgt vfio vfio-iommu-type1)|g" /etc/mkinitcpio.conf
    sudo mkinitcpio -p linux
    echo 'SUBSYSTEM=="vfio", OWNER="root", GROUP="kvm"' | sudo tee /etc/udev/rules.d/10-qemu.rules
    sudo usermod -aG kvm,libvirt $USER
    sudo sed -i '/^    options/ s/$/ iommu=pt intel_iommu=on/' /boot/loader/entries/arch.conf
    echo
    echo "Reboot and run this again for GVT-g"
}

kvmstep2() {
    echo "KVM qemu already installed"
    read -p "Setup GVT-g? (y/N) " gvtg
    [[ $gvtg != y && $gvtg != Y ]] && exit
    sudo sed -i '/^options/ s/$/ i915.enable_gvt=1 kvm.ignore_msrs=1/' /boot/loader/entries/arch.conf
    UUID=029a88f0-6c3e-4673-8b3c-097fe77d7c97
    sudo /bin/sh -c "echo $UUID > /sys/devices/pci0000:00/0000:00:02.0/mdev_supported_types/i915-GVTg_V5_4/create"
    echo "[Unit]
    Description=Create Intel GVT-g vGPU

    [Service]
    Type=oneshot
    ExecStart=/bin/sh -c \"echo '$UUID' > /sys/devices/pci0000:00/0000:00:02.0/mdev_supported_types/i915-GVTg_V5_4/create\"
    ExecStop=/bin/sh -c \"echo '1' > /sys/devices/pci0000:00/0000:00:02.0/$UUID/remove\"
    RemainAfterExit=yes

    [Install]
    WantedBy=graphical.target" | sudo tee /etc/systemd/system/gvtvgpu.service
    echo $UUID | tee gpu_uuid
    sudo systemctl enable gvtvgpu
    echo
    echo "Done! Reboot before continuing"
}

excludelist=(
".android"
".bash_history"
".bash_logout"
".cache"
".ccache"
".cemu"
".conan"
".config/Caprine"
".config/chromium/Default/File System"
".config/chromium/Default/Service Worker/CacheStorage"
".config/GitHub Desktop/Cache"
".config/google-chrome/Default/File System"
".config/google-chrome/Default/Service Worker/CacheStorage"
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
".local/share/Trash"
".npm"
".nuget"
".nv"
".nvidia-settings-rc"
".nx"
".osu"
".pam_environment"
".pipewire-media-session"
".profile"
".sudo_as_admin_successful"
".wine*"
".Xauthority"
".xsession-errors"
".zoom"
"Android"
"Programs/Genshin Impact"
"VMs"
)

RSYNC() {
    [[ $ArgR == full ]] && ArgR=
    [[ $ArgR != full && $ArgR != sparse ]] && Update=--update
    if [[ $3 == user ]]; then
        rm /tmp/excludelist 2>/dev/null
        for exclude in "${excludelist[@]}"; do
            echo "$exclude" >> /tmp/excludelist
        done
        sudo rsync -va $ArgR $Update --delete-after --info=progress2 --exclude-from=/tmp/excludelist $1 $2
    elif [[ $ArgR == sparse ]]; then
        [[ ! -d $2 ]] && ArgR="--ignore-existing --sparse" || ArgR="--existing --inplace"
        sudo rsync -va $ArgR --info=progress2 $1 $2
    else
        sudo rsync -va $ArgR $Update --delete-after --info=progress2 --exclude "VirtualBox VMs" --exclude "wine" $1 $2
    fi
}

BackupRestore() {
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
        Paths=("$HOME/" "/media/$USER/LukeHDD2/BackupsP/$USER/"
               "/mnt/Data/$USER/" "/media/$USER/LukeHDD2/BackupsP/Data/$USER/"
               "$HOME/.osu/" "/media/$USER/LukeHDD2/BackupsP/Data/osu/")
    elif [[ $Mode == pac ]]; then
        Paths=("/var/cache/pacman/pkg/" "/media/$USER/LukeHDD2/BackupsP/pkg/"
               "/var/cache/pacman/aur/" "/media/$USER/LukeHDD2/BackupsP/aur/")
    elif [[ $Mode == vm ]]; then
        Paths=("$HOME/KVM/" "/media/$USER/LukeHDD2/BackupsP/Data/KVM/")
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
    cd $HOME/.cache
    #ln -sf /mnt/Data/$USER/cache/wine
    #ln -sf /mnt/Data/$USER/cache/winetricks
    #ln -sf /mnt/Data/$USER/cache/paru
}

Plymouth() {
    sudo sed -i "s|HOOKS=(base udev autodetect modconf block keyboard encrypt lvm2 filesystems fsck)|HOOKS=(base udev plymouth plymouth-encrypt autodetect modconf block keyboard lvm2 filesystems fsck)|g" /etc/mkinitcpio.conf
    pac install plymouth
    sudo systemctl disable sddm
    sudo systemctl enable sddm-plymouth
}

vmwarei() {
    sudo sh $HOME/Documents/Documents/VMware-Player-16.0.0-17801498.x86_64.bundle --eulas-agreed --console --required
    vmwareu
}

vmwareu() {
    pac install vmware-systemd-services
    sudo vmware-modconfig --console --install-all
    sudo modprobe -a vmw_vmci vmmon
    sudo systemctl enable --now vmware vmware-usbarbitrator
}

opentabletdriver() {
    pac install dotnet-host dotnet-runtime dotnet-sdk opentabletdriver-git
    systemctl --user enable --now opentabletdriver
    #printf "blacklist wacom\nblacklist hid_uclogic\n" | sudo tee /etc/modprobe.d/blacklist.conf
}

# ----------------------------------

. /etc/os-release
clear
if [[ -z $UBUNTU_CODENAME && $ID != fedora ]]; then
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
