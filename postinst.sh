#!/bin/bash
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

packages=(
audacity-wxgtk2
f3
gallery-dl
masterpdfeditor-free
qdirstat
qsynth
qview
tartube
zoom
)

function MainMenu {
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

function installstuff {
    select opt in "Install AUR pkgs paru" "VirtualBox" "osu!" "Emulators" "Plymouth" "OpenTabletDriver" "KVM (with GVT-g)" "devkitPro" "VMware Player install" "VMware Player update"; do
        case $opt in
            "Install AUR pkgs paru" ) postinstall; break;;
            "VirtualBox" ) vbox; break;;
            "osu!" ) $HOME/Arch-Stuff/scripts/osu.sh install; break;;
            "Emulators" ) pac install dolphin-emu mgba-qt nestopia pcsx2 ppsspp snes9x-gtk; break;;
            "devkitPro" ) devkitPro; break;;
            "KVM (with GVT-g)" ) kvm; break;;
            "Plymouth" ) Plymouth; break;;
            "VMware Player install" ) vmwarei; break;;
            "VMware Player update" ) vmwareu; break;;
            "OpenTabletDriver" ) opentabletdriver; break;;
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
    
    pac install lib32-libva-intel-driver lib32-libva-mesa-driver lib32-vulkan-icd-loader lib32-vulkan-intel lib32-vulkan-radeon lutris wine winetricks
    sudo winetricks --self-update
    winetricks -q dxvk gdiplus vcrun2010 vcrun2013 vcrun2019 wmp9
    cd $HOME/.wine/drive_c/users/$USER
    rm -rf AppData 'Application Data'
    ln -sf $HOME/AppData
    ln -sf $HOME/AppData 'Application Data'
    
    fish -c 'set -U fish_user_paths $fish_user_paths /usr/sbin /sbin /usr/lib/ccache/bin'
    #sudo usermod -s /usr/bin/fish $USER
    
    sudo mkdir /var/cache/pacman/aur
    sudo chown $USER:users /var/cache/pacman/aur
    sudo sed -i "s|#PKGDEST=/home/packages|PKGDEST=/var/cache/pacman/aur|" /etc/makepkg.conf
    
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
    #sudo systemctl enable --now nmb smb
    
    echo "v4l2loopback" | sudo tee /etc/modules-load.d/v4l2loopback.conf
}

function adduser {
    read -p "[Input] Enter username: " username2
    echo "[Log] Creating user $username2"
    sudo useradd -m -g users -G audio,optical,storage -s /usr/bin/fish $username2
    echo "[Log] Running passwd $username2"
    sudo passwd $username2
}

function autocreate {
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

function vbox {
    pac install virtualbox virtualbox-host-dkms virtualbox-guest-iso virtualbox-ext-oracle
    sudo usermod -aG vboxusers $USER
    sudo modprobe vboxdrv
}

function nvidia {
    select opt in "NVIDIA Optimus+TLP" "NVIDIA 460" "NVIDIA 390"; do
        case $opt in
            "NVIDIA Optimus+TLP" ) nvidia4=optimus; break;;
            "NVIDIA 460" ) nvidia4=460; break;;
            "NVIDIA 390" ) nvidia4=390; break;;
            * ) exit;;
        esac
    done
    
    if [[ $nvidia4 == optimus ]] || [[ $nvidia4 == 460 ]]; then
        pac install nvidia-dkms lib32-nvidia-utils nvidia-settings opencl-nvidia lib32-opencl-nvidia
    elif [[ $nvidia4 == 390 ]]; then
        pac install nvidia-390xx-dkms lib32-nvidia-390xx-utils nvidia-390xx-settings opencl-nvidia-390xx lib32-opencl-nvidia-390xx
    fi
    
    if [[ $nvidia4 == optimus ]]; then
        pac install bbswitch-dkms nvidia-prime optimus-manager optimus-manager-git tlp tlp-rdw tlpui-git
        sudo systemctl enable tlp
    fi
}

function devkitPro {
    sudo pacman-key --recv BC26F752D25B92CE272E0F44F7FD5492264BB9D0 --keyserver keyserver.ubuntu.com
    sudo pacman-key --lsign BC26F752D25B92CE272E0F44F7FD5492264BB9D0
    sudo pacman -U --noconfirm https://downloads.devkitpro.org/devkitpro-keyring.pkg.tar.xz
    LINE='[dkp-libs]
    Server = https://downloads.devkitpro.org/packages
    [dkp-linux]
    Server = https://downloads.devkitpro.org/packages/linux/$arch/'
    FILE='/etc/pacman.conf'
    sudo grep -qF -- "$LINE" "$FILE" || echo "$LINE" | sudo tee -a "$FILE"
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
    sudo sed -i "s|MODULES=(i915 ext4)|MODULES=(i915 ext4 kvmgt vfio vfio-iommu-type1 vfio-mdev)|g" /etc/mkinitcpio.conf
    sudo mkinitcpio -p linux-zen
    echo 'SUBSYSTEM=="vfio", OWNER="root", GROUP="kvm"' | sudo tee /etc/udev/rules.d/10-qemu.rules
    sudo usermod -aG kvm,libvirt $USER 
    sudo smbpasswd -a $USER
    sudo sed -i '/^options/ s/$/ iommu=pt intel_iommu=on/' /boot/loader/entries/arch.conf
    echo
    echo "Reboot and run this again for GVT-g"
}

function kvmstep2 {
    read -p "GVT-g? (y/N) " gvtg 
    [[ $gvtg != y ]] && [[ $gvtg != Y ]] && exit
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

function RSYNC {
    if [[ $ArgR == sparse ]]; then
        [[ ! -d $2 ]] && ArgR=--sparse || ArgR=--inplace
    fi
    [[ $ArgR == full ]] && ArgR=
    [[ $ArgR != full ]] && [[ $ArgR != sparse ]] && Update=--update
    if [[ $3 == user ]]; then
        sudo rsync -va $ArgR $Update --delete-after --info=progress2 \
          --exclude '.bash_history' --exclude '.bash_logout' --exclude '.bashrc' \
          --exclude '.gitconfig' --exclude '.gtkrc-2.0' \
          --exclude '.nvidia-settings-rc' --exclude '.pam_environment' \
          --exclude '.profile' --exclude '.sudo_as_admin_successful' \
          --exclude '.Xauthority' --exclude '.xsession-errors' \
          --exclude 'KVM' --exclude 'VirtualBox VMs' \
          --exclude '.Genymobile/Genymotion/deployed' \
          --exclude '.config/GitHub Desktop/Cache' \
          --exclude 'Windows7' --exclude 'Windows10' \
          --exclude '.osu' --exclude '.cache' --exclude '.ccache' \
          --exclude '.cemu/wine' --exclude '.config/Caprine' \
          --exclude '.config/chromium/Default/File System' \
          --exclude '.config/chromium/Default/Service Worker/CacheStorage' \
          --exclude '.local/share/Kingsoft' --exclude '.local/share/Trash' \
          --exclude '.local/share/baloo' --exclude '.local/share/flatpak' \
          --exclude '.local/share/gvfs-metadata' --exclude '.local/share/lutris' \
          --exclude '.npm' --exclude '.nuget' --exclude '.nv' --exclude '.nx' \
          --exclude '.persepolis' --exclude '.pipewire-media-session' --exclude '.xsession-errors.old' \
          --exclude '.wine' --exclude '.wine_fl' --exclude '.wine_lutris' \
          --exclude '.wine_osu' --exclude '.zoom' --exclude '.ld.so' $1 $2
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
            /mnt/Data/$USER/ /media/$USER/LukeHDD2/BackupsP/Data/$USER/
            $HOME/.osu/ /media/$USER/LukeHDD2/BackupsP/Data/osu/)
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
    #ln -sf /mnt/Data/$USER/cache/wine
    #ln -sf /mnt/Data/$USER/cache/winetricks
    #ln -sf /mnt/Data/$USER/cache/paru
}

function Plymouth {
    sudo sed -i "s|HOOKS=(base udev autodetect modconf block keyboard encrypt lvm2 resume filesystems fsck)|HOOKS=(base udev plymouth plymouth-encrypt autodetect modconf block keyboard lvm2 resume filesystems fsck)|g" /etc/mkinitcpio.conf
    pac install plymouth
    sudo systemctl disable sddm
    sudo systemctl enable sddm-plymouth
}

function vmwarei {
    sudo sh $HOME/Documents/Documents/VMware-Player-16.0.0-17801498.x86_64.bundle --eulas-agreed --console --required
    vmwareu
}

function vmwareu {
    pac install vmware-systemd-services
    sudo vmware-modconfig --console --install-all
    sudo modprobe -a vmw_vmci vmmon
    sudo systemctl enable --now vmware vmware-usbarbitrator
}

function opentabletdriver {
    pac install dotnet-host dotnet-runtime dotnet-sdk opentabletdriver-git
    systemctl --user enable --now opentabletdriver
}

# ----------------------------------

. /etc/os-release
clear
if [[ -z $UBUNTU_CODENAME ]] && [[ $ID != fedora ]]; then
    echo "LukeZGD Arch Post-Install Script"
    echo "This script will assume that you have a working Internet connection"
    echo
    if [ ! $(which paru) ]; then
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
