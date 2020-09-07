#!/bin/bash

trap 'rm failed.txt 2>/dev/null; exit' INT TERM EXIT
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

packages=(
checkra1n-cli
gconf
exfat-utils-nofuse
libirecovery-git
ncurses5-compat-libs
python2-twodict-git
caprine
futurerestore-s0uthwest-git
gallery-dl
github-desktop-bin
idevicerestore-git
masterpdfeditor-free
mystiq
partialzipbrowser-git
qdirstat
qsynth
teams
ttf-wps-fonts
ventoy-bin
wps-office
youtube-dl-gui-git
zoom
)

function MainMenu {
    select opt in "Install stuff" "Run postinstall commands" "Backup and restore" "Add user" "NVIDIA Optimus+TLP" "NVIDIA 390xx"; do
        case $opt in
            "Install stuff" ) installstuff; break;;
            "Run postinstall commands" ) postinstallcomm; break;;
            "Backup and restore" ) BackupRestore; break;;
            "Add user" ) adduser; break;;
            "NVIDIA Optimus+TLP" ) laptop; break;;
            "NVIDIA 390xx" ) 390xx; break;;
        * ) exit;;
        esac
    done
}

function installstuff {
    select opt in "Install AUR pkgs yay" "VirtualBox" "osu!" "Emulators" "devkitPro" "KVM (with GVT-g)" "Plymouth"; do
        case $opt in
            "Install AUR pkgs yay" ) postinstall; break;;
            "VirtualBox" ) vbox; break;;
            "osu!" ) osu; break;;
            "Emulators" ) emulatorsinstall; break;;
            "devkitPro" ) devkitPro; break;;
            "KVM (with GVT-g)" ) kvm; break;;
            "Plymouth" ) Plymouth; break;;
            * ) exit;;
        esac
    done
}

function installpac {
    git clone https://aur.archlinux.org/$1.git
    cd $1
    makepkg -sic --noconfirm
    cd ..
    rm -rf $1
}

function postinstall {
    gpg --keyserver keys.gnupg.net --recv-keys 702353E0F7E48EDB
    for package in "${packages[@]}"; do
        sudo pacman -U --noconfirm --needed /var/cache/pacman/aur/$package*.zst 2>/dev/null
        if [ $? == 1 ]; then
        echo $package | tee -a failed.txt
        fi
    done
    IFS=$'\r\n' GLOBIGNORE='*' command eval 'failed=($(cat failed.txt))'
    for package in "${failed[@]}"; do
        pac install $package
    done
}

function postinstallcomm {
    PackagesDir=$HOME/Documents/Packages
    [ ! -e $PackagesDir/ttf-packages.zip ] && curl -L https://github.com/LukeZGD/Arch-Stuff/releases/download/stuff/ttf-packages.zip -o $PackagesDir/ttf-packages.zip
    unzip $PackagesDir/ttf-packages.zip -d $PackagesDir
    sudo pacman -U --noconfirm --needed $PackagesDir/*.xz $PackagesDir/*.gz $PackagesDir/*.zst #for veikk driver and fonts
    rm -f $PackagesDir/*.xz $PackagesDir/*.gz $PackagesDir/*.zst
    sudo timedatectl set-ntp true
    sudo modprobe ohci_hcd
    setxkbmap -layout us
    #xmodmap -e 'keycode 84 = Down KP_5 Down KP_5'
    sudo cp $BASEDIR/postinst.sh /usr/bin/postinst
    cd $BASEDIR/scripts
    sudo cp lgdutil.sh /usr/bin/lgdutil
    sudo cp pac.sh /usr/bin/pac
    sudo cp touhou.sh /usr/bin/touhou
    sudo chmod +x /usr/bin/lgdutil /usr/bin/pac /usr/bin/postinst
    # home symlinks
    cd $HOME/.config
    ln -sf /mnt/Data/$USER/config/PCSX2/
    ln -sf /mnt/Data/$USER/config/ppsspp/
    ln -sf /mnt/Data/$USER/config/rpcs3/
    cd $HOME/.local/share
    ln -sf /mnt/Data/$USER/share/citra-emu/
    ln -sf /mnt/Data/$USER/share/dolphin-emu/
    ln -sf /mnt/Data/$USER/share/osu/
    ln -sf /mnt/Data/$USER/share/yuzu/
    cd $HOME/.cemu
    ln -sf /mnt/Data/$USER/cemu/controllerProfiles/
    ln -sf /mnt/Data/$USER/cemu/graphicPacks/
    ln -sf /mnt/Data/$USER/cemu/mlc01/
    ln -sf /mnt/Data/$USER/cemu/shaderCache/
    cd $HOME/.cache
    ln -sf /mnt/Data/$USER/cache/wine
    ln -sf /mnt/Data/$USER/cache/winetricks
    ln -sf /mnt/Data/$USER/cache/yay
    echo "[Log] input-veikk-startup service"
    echo '[Unit]
    Description=input-veikk-startup

    [Service]
    Type=oneshot
    ExecStart=/usr/bin/input-veikk-startup
    RemainAfterExit=yes

    [Install]
    WantedBy=multi-user.target' | sudo tee /usr/lib/systemd/system/input-veikk-startup.service
    echo '#!/bin/bash
    echo 0,0,345,345 | tee /sys/module/veikk/parameters/bounds_map
    exit 0' | sudo tee /usr/bin/input-veikk-startup
    sudo chmod +x /usr/bin/input-veikk-startup
    sudo systemctl enable input-veikk-startup
    echo 'export DEVKITPRO=/opt/devkitpro
    export DEVKITARM=/opt/devkitpro/devkitARM
    export DEVKITPPC=/opt/devkitpro/devkitPPC' | tee $HOME/.profile
    
    if [ $(which pacman-mirrors) ]; then
        echo "[Log] Manjaro post-install"
        sudo pacman-mirrors --api --set-branch testing --continent
        pac purge appimagelauncher gwenview kget lib32-fluidsynth manjaro-application-utility manjaro-pulse pamac-cli pamac-common pamac-flatpak-plugin pamac-gtk pamac-snap-plugin pamac-tray-appindicator vlc yakuake
        systemctl --global disable pipewire pipewire.socket
        sudo $BASEDIR/chroot.sh
    fi
    
    sudo pacman -Sy --needed --noconfirm fish nano-syntax-highlighting wine wine-gecko wine-mono winetricks
    winecfg
    cd $HOME/.wine/drive_c/users/$USER
    rm -rf AppData 'Application Data'
    ln -sf $HOME/AppData
    ln -sf $HOME/AppData 'Application Data'
    fish -c 'set -U fish_user_paths $fish_user_paths /usr/sbin /sbin /usr/lib/ccache/bin'
    sudo usermod -s /usr/bin/fish $USER
    
    sudo mkdir /var/cache/pacman/aur
    sudo chown $USER:users /var/cache/pacman/aur
    sudo sed -i "s|#PKGDEST=/home/packages|PKGDEST=/var/cache/pacman/aur|" /etc/makepkg.conf
}

function adduser {
    read -p "[Input] Enter username: " username2
    echo "[Log] Creating user $username2"
    sudo useradd -m -g users -G audio -s /usr/bin/fish $username2
    echo "[Log] Running passwd $username2"
    sudo passwd $username2
}

function autocreate {
    a=$1
    [ ! -z $2 ] && a=$2
    echo "[Desktop Entry]
    Encoding=UTF-8
    Version=0.9.4
    Type=Application
    Name=$1
    Exec=$a
    RunHook=0
    StartupNotify=false
    Terminal=false
    Hidden=false" | tee $HOME/.config/autostart/$1.desktop
}

function vbox {
    pac install virtualbox virtualbox-host-dkms virtualbox-guest-iso virtualbox-ext-oracle
    sudo usermod -aG vboxusers $USER
    sudo modprobe vboxdrv
}

function laptop {
    pac install nvidia-dkms lib32-nvidia-utils bbswitch-dkms nvidia-settings tlp tlp-rdw tlpui-git optimus-manager optimus-manager-qt vulkan-icd-loader lib32-vulkan-icd-loader vulkan-intel lib32-vulkan-intel intel-media-driver libva-intel-driver
    sudo systemctl enable tlp
    if [ $(which pacman-mirrors) ]; then
        sudo sed -i '/DisplayCommand/s/^/#/g' /etc/sddm.conf
        sudo sed -i '/DisplayStopCommand/s/^/#/g' /etc/sddm.conf
        sudo systemctl disable bumblebeed
    fi
}

function 390xx {
    pac install nvidia-390xx-dkms lib32-nvidia-390xx-utils nvidia-390xx-settings
}

function emulatorsinstall {
    pac install cemu citra-canary-git dolphin-emu fceux melonds-git mgba-qt pcsx2 ppsspp rpcs3-bin yuzu-mainline-bin
}

function osu {
    $BASEDIR/scripts/osu.sh install
}

function devkitPro {
    sudo pacman-key --recv F7FD5492264BB9D0
    sudo pacman-key --lsign F7FD5492264BB9D0
    sudo pacman -U https://downloads.devkitpro.org/devkitpro-keyring-r1.787e015-2-any.pkg.tar.xz
    echo '[dkp-libs]
    Server = https://downloads.devkitpro.org/packages
    [dkp-linux]
    Server = https://downloads.devkitpro.org/packages/linux' | sudo tee -a /etc/pacman.conf
    sudo pacman -Sy --noconfirm 3ds-dev switch-dev
}

function kvm {
    if [ -e /sys/devices/pci0000:00/0000:00:02.0/mdev_supported_types ] && [ ! -e /etc/systemd/system/gvtvgpu.service ]; then
        kvmstep2
    else
        kvmstep1
    fi
}

function kvmstep1 {
    pac install virt-manager qemu vde2 ebtables dnsmasq bridge-utils openbsd-netcat

    echo "[global]
    allow insecure wide links = yes
    workgroup = WORKGROUP
    netbios name = $USER

    [LinuxHost]
    comment = Host Share
    path = $HOME
    valid users = $USER
    public = no
    writable = yes
    printable = no
    follow symlinks = yes
    wide links = yes" | sudo tee /etc/samba/smb.conf

    sudo systemctl enable --now libvirtd smb nmb
    sudo sed -i "s|MODULES=(ext4)|MODULES=(ext4 kvmgt vfio vfio-iommu-type1 vfio-mdev)|g" /etc/mkinitcpio.conf
    sudo mkinitcpio -p linux-zen
    echo 'SUBSYSTEM=="vfio", OWNER="root", GROUP="kvm"' | sudo tee /etc/udev/rules.d/10-qemu.rules
    sudo usermod -aG kvm,libvirt $USER 
    sudo smbpasswd -a $USER
    sudo sed -i '/^options/ s/$/ i915.enable_gvt=1 kvm.ignore_msrs=1 iommu=pt intel_iommu=on/' /boot/loader/entries/arch.conf
    echo
    echo "Reboot and run this again for GVT-g"
}

function kvmstep2 {
    read -p "GVT-g? (y/N) " gvtg 
    if [[ $gvtg != y ]] && [[ $gvtg != Y ]]; then
        exit
    fi
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

function RSYNC {
    if [[ $ArgR == sparse ]]; then
        [[ ! -d $2 ]] && ArgR=--sparse || ArgR=--inplace
    fi
    [[ $ArgR == full ]] && ArgR=--full
    [[ $ArgR != full ]] && [[ $ArgR != sparse ]] && Update=--update
    if [[ $3 == user ]]; then
        sudo rsync -va $ArgR $Update --delete-after --info=progress2 --exclude '.ccache' --exclude '.local/share/lutris' --exclude 'KVM' --exclude 'osu' --exclude '.cache' --exclude '.local/share/baloo' --exclude '.local/share/Trash' --exclude '.config/chromium/Default/Service Worker/CacheStorage' --exclude '.config/chromium/Default/File System' --exclude '.local/share/gvfs-metadata' --exclude '.wine' --exclude '.wine_fl' --exclude '.wine_lutris' --exclude '.wine_osu' --exclude '.cemu/wine' $1 $2
    else
        sudo rsync -va $ArgR $Update --delete-after --info=progress2 --exclude 'VirtualBox VMs' $1 $2
    fi
}

function BackupRestore {
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
    if [ $Mode == user ]; then
        Paths=($HOME/ /run/media/$USER/LukeHDD2/Backups/$USER/
            /mnt/Data/$USER/ /run/media/$USER/LukeHDD2/Backups/Data/$USER/
            $HOME/osu/ /run/media/$USER/LukeHDD2/Backups/Data/osu/)
    elif [ $Mode == pac ]; then
        Paths=(/var/cache/pacman/pkg/ /run/media/$USER/LukeHDD2/Backups/pkg/
               /var/cache/pacman/aur/ /run/media/$USER/LukeHDD2/Backups/aur/)
    elif [ $Mode == vm ]; then
        Paths=($HOME/KVM/ /run/media/$USER/LukeHDD2/Backups/Data/KVM/)
    fi
    if [ $Action == Backup ]; then
        if [ $Mode == user ]; then
        RSYNC ${Paths[0]} ${Paths[1]} user
        RSYNC ${Paths[2]} ${Paths[3]}
        RSYNC ${Paths[4]} ${Paths[5]}
        elif [ $Mode == pac ]; then
        RSYNC ${Paths[0]} ${Paths[1]}
        RSYNC ${Paths[2]} ${Paths[3]}
        elif [ $Mode == vm ]; then
        RSYNC ${Paths[0]} ${Paths[1]}
        fi
    elif [ $Action == Restore ]; then
        if [ $Mode == user ]; then
        select opt in "Update restore" "Full restore"; do
            case $opt in
            "Update restore" ) Restoreuser; break;;
            "Full restore" ) ArgR=full; Restoreuser; break;;
            * ) exit;;
            esac
        done
        elif [ $Mode == pac ]; then
        RSYNC ${Paths[1]} ${Paths[0]}
        RSYNC ${Paths[3]} ${Paths[2]}
        elif [ $Mode == vm ]; then
        RSYNC ${Paths[1]} ${Paths[0]}
        fi
    fi
}

function Restoreuser {
    RSYNC ${Paths[1]} ${Paths[0]} user
    RSYNC ${Paths[3]} ${Paths[2]}
    RSYNC ${Paths[5]} ${Paths[4]}
    cd $HOME/.cache
    ln -sf /mnt/Data/$USER/cache/wine
    ln -sf /mnt/Data/$USER/cache/winetricks
    ln -sf /mnt/Data/$USER/cache/yay
}

function Plymouth {
    sudo sed -i "s|HOOKS=(base udev autodetect modconf block keyboard encrypt lvm2 resume filesystems fsck)|HOOKS=(base udev plymouth plymouth-encrypt autodetect modconf block keyboard lvm2 resume filesystems fsck)|g" /etc/mkinitcpio.conf
    sudo sed -i "s|MODULES=(ext4)|MODULES=(i915 ext4)|g" /etc/mkinitcpio.conf
    pac install plymouth
    sudo systemctl disable sddm
    sudo systemtcl enable sddm-plymouth
}

# ----------------------------------

clear
echo "LukeZGD Arch Post-Install Script"
echo "This script will assume that you have a working Internet connection"
echo

if [ ! $(which yay) ]; then
    echo "No yay detected, installing yay"
    installpac yay-bin
    sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
fi

MainMenu
