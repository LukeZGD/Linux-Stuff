#!/bin/bash
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

packages=(
checkra1n-cli
gconf
libirecovery-git
ncurses5-compat-libs
etcher-cli-bin
f3-qt-git
gallery-dl
github-desktop-bin
idevicerestore-git
masterpdfeditor-free
mystiq
qdirstat
qsynth
qview
tartube
ttf-wps-fonts
wps-office
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
    select opt in "Install AUR pkgs paru" "VirtualBox" "osu!" "Emulators" "devkitPro" "KVM (with GVT-g)" "Plymouth" "VMware Player install" "VMware Player update"; do
        case $opt in
            "Install AUR pkgs paru" ) postinstall; break;;
            "VirtualBox" ) vbox; break;;
            "osu!" ) $HOME/Arch-Stuff/scripts/osu.sh install; break;;
            "Emulators" ) emulatorsinstall; break;;
            "devkitPro" ) devkitPro; break;;
            "KVM (with GVT-g)" ) kvm; break;;
            "Plymouth" ) Plymouth; break;;
            "VMware Player install" ) vmwarei; break;;
            "VMware Player update" ) vmwareu; break;;
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
    echo "keyserver keyserver.ubuntu.com" | tee $HOME/.gnupg/gpg.conf
    rm /tmp/failed.txt
    for package in "${packages[@]}"; do
        sudo pacman -U --noconfirm --needed /var/cache/pacman/aur/$package*.zst 2>/dev/null
        if [ $? == 1 ]; then
        echo $package | tee -a /tmp/failed.txt
        fi
    done
    IFS=$'\r\n' GLOBIGNORE='*' command eval 'failed=($(cat /tmp/failed.txt))'
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
    sudo rm -rf /media
    sudo ln -sf /run/media /media
    sudo ln -sf $BASEDIR/postinst.sh /usr/local/bin/postinst
    sudo ln -sf $BASEDIR/scripts/lgdutil.sh /usr/local/bin/lgdutil
    sudo ln -sf $BASEDIR/scripts/pac.sh /usr/local/bin/pac
    sudo ln -sf $BASEDIR/scripts/touhou.sh /usr/local/bin/touhou
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
    ln -sf /mnt/Data/$USER/cache/paru
    cd $BASEDIR
    
    if [ $(which pacman-mirrors) ]; then
        echo "[Log] Manjaro post-install"
        sudo pacman-mirrors --api --set-branch testing --continent
        pac purge appimagelauncher gwenview kget lib32-fluidsynth manjaro-application-utility manjaro-pulse pamac-cli pamac-common pamac-flatpak-plugin pamac-gtk pamac-snap-plugin pamac-tray-appindicator vlc yakuake
        systemctl --global disable pipewire pipewire.socket
        sudo $BASEDIR/chroot.sh
    fi
    
    pac install dxvk-bin fish lutris nano-syntax-highlighting wine-staging wine-gecko-bin wine-mono-bin winetricks
    
    winetricks -q gdiplus vcrun2013 vcrun2015 wmp9
    #setup_dxvk install
    cd $HOME/.wine/drive_c/users/$USER
    rm -rf AppData 'Application Data'
    ln -sf $HOME/AppData
    ln -sf $HOME/AppData 'Application Data'
    
    fish -c 'set -U fish_user_paths $fish_user_paths /usr/sbin /sbin /usr/lib/ccache/bin'
    sudo usermod -s /usr/bin/fish $USER
    
    sudo mkdir /var/cache/pacman/aur
    sudo chown $USER:users /var/cache/pacman/aur
    sudo sed -i "s|#PKGDEST=/home/packages|PKGDEST=/var/cache/pacman/aur|" /etc/makepkg.conf
    
    echo "[global]
    allow insecure wide links = yes
    workgroup = WORKGROUP
    netbios name = $(hostname)

    [LinuxHost]
    comment = Host Share
    path = $HOME
    valid users = $USER
    public = no
    writable = yes
    printable = no
    follow symlinks = yes
    wide links = yes" | sudo tee /etc/samba/smb.conf
    sudo systemctl enable --now input-veikk-startup nmb smb
}

function adduser {
    read -p "[Input] Enter username: " username2
    echo "[Log] Creating user $username2"
    sudo useradd -m -g users -G audio,optical,storage -s /usr/bin/fish $username2
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
    pac install virtualbox virtualbox-host-modules-arch virtualbox-guest-iso virtualbox-ext-oracle
    sudo usermod -aG vboxusers $USER
    sudo modprobe vboxdrv
}

function laptop {
    pac install nvidia lib32-nvidia-utils bumblebee bbswitch nvidia-settings tlp tlp-rdw tlpui-git optimus-manager optimus-manager-qt vulkan-icd-loader lib32-vulkan-icd-loader vulkan-intel lib32-vulkan-intel intel-media-driver libva-intel-driver
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
    pac install cemu citra-canary-git dolphin-emu mednafen mednaffe melonds-git mgba-qt pcsx2 ppsspp rpcs3-bin
}

function devkitPro {
    sudo pacman-key --recv BC26F752D25B92CE272E0F44F7FD5492264BB9D0 --keyserver keyserver.ubuntu.com
    sudo pacman-key --lsign BC26F752D25B92CE272E0F44F7FD5492264BB9D0
    sudo pacman -U --noconfirm https://downloads.devkitpro.org/devkitpro-keyring.pkg.tar.xz
    echo '[dkp-libs]
    Server = https://downloads.devkitpro.org/packages
    [dkp-linux]
    Server = https://downloads.devkitpro.org/packages/linux/$arch/' | sudo tee -a /etc/pacman.conf
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
    
    sudo systemctl enable --now libvirtd
    sudo sed -i "s|MODULES=(ext4)|MODULES=(ext4 kvmgt vfio vfio-iommu-type1 vfio-mdev)|g" /etc/mkinitcpio.conf
    sudo mkinitcpio -p linux
    echo 'SUBSYSTEM=="vfio", OWNER="root", GROUP="kvm"' | sudo tee /etc/udev/rules.d/10-qemu.rules
    sudo usermod -aG kvm,libvirt $USER 
    sudo smbpasswd -a $USER
    sudo sed -i '/^options/ s/$/ i915.enable_gvt=1 kvm.ignore_msrs=1 iommu=pt intel_iommu=on/' /boot/loader/entries/arch.conf
    echo
    echo "Reboot and run this again for GVT-g"
}

function kvmstep2 {
    read -p "GVT-g? (y/N) " gvtg 
    [[ $gvtg != y ]] && [[ $gvtg != Y ]] && exit
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
    [[ $ArgR == full ]] && ArgR=
    [[ $ArgR != full ]] && [[ $ArgR != sparse ]] && Update=--update
    if [[ $3 == user ]]; then
        sudo rsync -va $ArgR $Update --delete-after --info=progress2 \
          --exclude 'KVM' --exclude 'VirtualBox VMs' \
          --exclude '.Genymobile/Genymotion/deployed' \
          --exclude '.config/GitHub Desktop/Cache' \
          --exclude 'Windows7' --exclude 'Windows10' \
          --exclude 'osu' --exclude '.cache' --exclude '.ccache' \
          --exclude '.cemu/wine' --exclude '.config/Caprine' \
          --exclude '.config/chromium/Default/File System' \
          --exclude '.config/chromium/Default/Service Worker/CacheStorage' \
          --exclude '.local/share/Kingsoft' --exclude '.local/share/Trash' \
          --exclude '.local/share/baloo' --exclude '.local/share/gvfs-metadata' --exclude '.local/share/lutris' \
          --exclude '.wine' --exclude '.wine_fl' --exclude '.wine_lutris' --exclude '.wine_osu' $1 $2
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
        Paths=($HOME/ /media/$USER/LukeHDD2/BackupsP/$USER/
            /mnt/Data/$USER/ /media/$USER/LukeHDD2/BackupsP/Data/$USER/)
            #$HOME/osu/ /media/$USER/LukeHDD2/BackupsP/Data/osu/)
    elif [ $Mode == pac ]; then
        Paths=(/var/cache/pacman/pkg/ /media/$USER/LukeHDD2/BackupsP/pkg/
               /var/cache/pacman/aur/ /media/$USER/LukeHDD2/BackupsP/aur/)
    elif [ $Mode == vm ]; then
        Paths=($HOME/KVM/ /media/$USER/LukeHDD2/BackupsP/Data/KVM/)
    fi
    if [ $Action == Backup ]; then
        if [ $Mode == user ]; then
        RSYNC ${Paths[0]} ${Paths[1]} user
        RSYNC ${Paths[2]} ${Paths[3]}
        #RSYNC ${Paths[4]} ${Paths[5]}
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
    #ln -sf /mnt/Data/$USER/cache/wine
    #ln -sf /mnt/Data/$USER/cache/winetricks
    #ln -sf /mnt/Data/$USER/cache/paru
}

function Plymouth {
    sudo sed -i "s|HOOKS=(base udev autodetect modconf block keyboard encrypt lvm2 resume filesystems fsck)|HOOKS=(base udev plymouth plymouth-encrypt autodetect modconf block keyboard lvm2 resume filesystems fsck)|g" /etc/mkinitcpio.conf
    sudo sed -i "s|MODULES=(ext4)|MODULES=(i915 ext4)|g" /etc/mkinitcpio.conf
    pac install plymouth
    sudo systemctl disable sddm
    sudo systemctl enable sddm-plymouth
}

function vmwarei {
    sudo sh $HOME/Documents/VMware-Player-16.0.0-16894299.x86_64.bundle --eulas-agreed --console --required
    vmwareu
}

function vmwareu {
    pac install vmware-systemd-services
    sudo vmware-modconfig --console --install-all
    sudo modprobe -a vmw_vmci vmmon
    sudo systemctl enable --now vmware vmware-usbarbitrator
}

# ----------------------------------

. /etc/os-release
if [[ -z $UBUNTU_CODENAME ]] && [[ $ID != fedora ]]; then
    clear
    echo "LukeZGD Arch Post-Install Script"
    echo "This script will assume that you have a working Internet connection"
    echo
    if [ ! $(which paru) ]; then
        echo "No paru detected, installing paru"
        installpac paru-bin
        sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
    fi
elif [[ $1 != BackupRestore ]]; then
    echo "Warning: Not an Arch system!"
fi

if [[ $1 == BackupRestore ]]; then
    BackupRestore
else
    MainMenu
fi
