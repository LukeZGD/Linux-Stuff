#!/bin/bash
BASEDIR="$(dirname $(type -p $0))"
. $HOME/Arch-Stuff/scripts/preparelutris.sh

packages=(
cpu-x
earlyoom
f3
gallery-dl
github-desktop-bin
kde-rounded-corners
legendary
masterpdfeditor-free
mystiq
ndstrim
nohang-git
ocs-url
portsmf-git
protontricks
qdirstat
qsynth
rustdesk-bin
shellcheck-bin
tenacity-wxgtk3-git
ventoy-bin
viber
waifu2x-ncnn-vulkan-bin
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
    select opt in "Install AUR pkgs paru" "VirtualBox+Docker" "osu!" "Emulators" "Plymouth" "OpenTabletDriver" "KVM w/ virt-manager" "VMware" "MS office" "FL Studio" "Brother DCP-L2540DW" "JP Input" "Chaotic AUR" "Waydroid" "auto-cpufreq"; do
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
        "FL Studio" ) FL; break;;
        "Brother DCP-L2540DW" ) brother_dcpl2540dw; break;;
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
    echo 'options kvm_amd nested=1' | sudo tee /etc/modprobe.d/kvm.conf
}

waydroid() {
    pac install lzip waydroid-image-gapps weston waydroid python-gbinder python-tqdm libgbinder lxc cython nftables dnsmasq xorg-xwayland
    sudo waydroid init -s GAPPS -f
    # https://github.com/casualsnek/waydroid_script
    cd $HOME/Documents/GitHub/waydroid_script
    sudo python3 waydroid_extras.py -l
    echo "start waydroid:
    weston (if on x-session)
    sudo systemctl start waydroid-container
    export XDG_SESSION_TYPE='wayland'; export DISPLAY=':1'; waydroid show-full-ui"
}

jpmozc() {
    pac install fcitx5-im fcitx5-mozc kcm-fcitx5
    printf "\nGTK_IM_MODULE=fcitx\nQT_IM_MODULE=fcitx\nXMODIFIERS=@im=fcitx" | sudo tee -a /etc/environment
    cp /etc/xdg/autostart/org.fcitx.Fcitx5.desktop $HOME/.config/autostart
}

brother_dcpl2540dw() {
    read -p "[Input] IP Address of printer: " ip
    pac install brother-dcpl2540dw-cups brscan4
    sudo brsaneconfig4 -a name="Brother" model="DCP-L2540DW" ip=$ip
}

msoffice() {
    WINEPREFIX=$HOME/.wine_office2010 WINEARCH=win32 winetricks winxp
    WINEPREFIX=$HOME/.wine_office2010 winetricks -q msxml6 riched20 gdiplus richtx32
    WINEPREFIX=$HOME/.wine_office2010 wine reg add 'HKEY_CURRENT_USER\Control Panel\Desktop' /t REG_DWORD /v LogPixels /d 144 /f
    echo "prepared wineprefix"
    echo "now run: WINEPREFIX=~/.wine_office2010 WINEARCH=win32 wine /path/to/setup.exe"
    echo "also add the kwinrule"
}

FL() {
    WINEPREFIX=$HOME/.wine_fl wine reg add 'HKEY_CURRENT_USER\Control Panel\Desktop' /t REG_DWORD /v LogPixels /d 120 /f
    cd "$HOME/.wine_fl/drive_c/Program Files (x86)/"
    ln -sf "../Program Files/Image-Line/" .
    mkdir -p "$HOME/.wine_fl/drive_c/users/$USER/Start Menu/Programs/Image-Line/"
    cp "$HOME/Documents/FL Studio 20 (32bit).lnk" "$HOME/.wine_fl/drive_c/users/$USER/Start Menu/Programs/Image-Line/"
    echo "prepared wineprefix"
    echo "now run: WINEPREFIX=~/.wine_fl wine /path/to/flsetup.exe"
    echo "also install in Program Files"
}

chaoticaur() {
    sudo pacman-key --recv-key FBA220DFC880C036 --keyserver keyserver.ubuntu.com
    sudo pacman-key --lsign-key FBA220DFC880C036
    sudo pacman -U --noconfirm --needed 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
    printf "[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n" | sudo tee -a /etc/pacman.conf
}

emulators() {
    pac install dolphin-emu fceux melonds-bin mgba-qt pcsx2 ppsspp rpcs3-udev snes9x-gtk
    WINEPREFIX=$HOME/.cemu/wine wine reg add 'HKEY_CURRENT_USER\Control Panel\Desktop' /t REG_DWORD /v LogPixels /d 144 /f
    WINEPREFIX=$HOME/.cemu/wine winetricks -q vcrun2017
    mkdir $HOME/.cemu
    cd $HOME/.cemu
    #ln -s /usr/share/cemu/Cemu.exe .
    #ln -s /usr/share/cemu/cemuhook.dll .
    #ln -s /usr/share/cemu/keystone.dll .
    #ln -s /usr/share/cemu/sharedFonts/ .
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
    cd $HOME/.cache
    ln -sf /mnt/Data/$USER/cache/paru
    sudo ln -sf $HOME/Arch-Stuff/postinst.sh /usr/local/bin/postinst
    sudo ln -sf $HOME/Arch-Stuff/scripts/pac.sh /usr/local/bin/pac

    echo "keyserver keyserver.ubuntu.com" | tee $HOME/.gnupg/gpg.conf
    pac install "${packages[@]}"
    pac install persepolis
    for pkg in $HOME/Programs/Packages/*; do sudo pacman -U --noconfirm --needed $pkg; done
    sudo systemctl enable --now nohang-desktop
}

preparewineprefix() {
    [[ -n $1 ]] && export WINEPREFIX=$1 || export WINEPREFIX=$HOME/.wine
    [[ -n $2 ]] && export WINEARCH=$2 || export WINEARCH=win64
    wine reg add 'HKEY_CURRENT_USER\Control Panel\Desktop' /t REG_DWORD /v LogPixels /d 120 /f
    wine reg add 'HKEY_CURRENT_USER\Software\Wine\DllOverrides' /t REG_SZ /v dsdmo /f
    cd $WINEPREFIX/drive_c
    rm -rf ProgramData
    ln -sf $HOME/AppData ProgramData
    cd $WINEPREFIX/drive_c/users/$USER
    rm -rf AppData 'Application Data' 'Saved Games'
    ln -sf $HOME/AppData
    ln -sf $HOME/AppData 'Application Data'
    ln -sf $HOME/AppData 'Saved Games'
}

postinstallcomm() {
    balooctl disable
    setxkbmap -layout us
    cd $HOME/.cache
    ln -sf /mnt/Data/$USER/cache/wine
    ln -sf /mnt/Data/$USER/cache/winetricks
    ln -sf /mnt/Data/$USER/cache/paru
    cd $BASEDIR

    sudo ln -sf $HOME/Arch-Stuff/postinst.sh /usr/local/bin/postinst
    sudo ln -sf $HOME/Arch-Stuff/scripts/pac.sh /usr/local/bin/pac
    
    pac install lib32-gst-plugins-base lib32-gst-plugins-good lib32-libva-mesa-driver lib32-vulkan-icd-loader lib32-vulkan-radeon lutris wine-staging winetricks
    sudo winetricks --self-update
    winetricks -q gdiplus vcrun2010 vcrun2013 vcrun2019 win10 wmp11
    $HOME/Documents/dxvk/setup_dxvk.sh install
    preparewineprefix

    preparelutris "$lutrisver" "$lutrissha1"
    preparewineprefix "$HOME/.wine_lutris"
    WINEPREFIX=$HOME/.wine_lutris winetricks -q quartz win10 wmp11

    preparewineprefix "$HOME/.wine_lutris2"
    WINEPREFIX=$HOME/.wine_lutris2 winetricks -q win10
    # https://github.com/Sporif/dxvk-async
    WINEPREFIX=$HOME/.wine_lutris2 $HOME/Documents/dxvk/setup_dxvk.sh install
    # https://github.com/z0z0z/mf-install
    WINEPREFIX=$HOME/.wine_lutris2 $HOME/Documents/mf-install/mf-install.sh

    preparelutris "fshack-5.0" "736e7499d03d1bc60b13a43efa5fa93450140e9d"
    preparewineprefix "$HOME/.wine_lutris32" win32
    WINEPREFIX=$HOME/.wine_lutris32 WINEARCH=win32 winetricks -q quartz wmp9
    
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
    sudo systemctl enable --now docker
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
        pac install nvidia-dkms lib32-nvidia-utils nvidia-settings opencl-nvidia lib32-opencl-nvidia
    elif [[ -n $nvidia4 ]]; then
        pac install nvidia-${nvidia4}xx-dkms lib32-nvidia-${nvidia4}xx-utils nvidia-${nvidia4}xx-settings opencl-nvidia-${nvidia4}xx lib32-opencl-nvidia-${nvidia4}xx
    fi
    
    if [[ $nvidia4 == optimus ]]; then
        pac install bbswitch-dkms nvidia-prime optimus-manager optimus-manager-qt
    fi
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
".npm"
".nuget"
".nv"
".nvidia-settings-rc"
".nx"
".osu"
".pam_environment"
".pipewire-media-session"
".profile"
".rustup"
".steam"
".sudo_as_admin_successful"
".wine*"
".Xauthority"
".xsession-errors"
".zoom"
"Android"
"Programs/Games"
"VMs"
)

RSYNC() {
    [[ $ArgR != full && $ArgR != sparse ]] && Update=--update
    [[ $ArgR == full ]] && ArgR=
    if [[ $3 == user ]]; then
        rm /tmp/excludelist 2>/dev/null
        for exclude in "${excludelist[@]}"; do
            echo "$exclude" >> /tmp/excludelist
        done
        sudo rsync -va $ArgR $Update --del --info=progress2 --exclude-from=/tmp/excludelist $1 $2
    elif [[ $ArgR == sparse ]]; then
        [[ ! -d $2 ]] && ArgR="--ignore-existing --sparse" || ArgR="--existing --inplace"
        sudo rsync -va $ArgR --info=progress2 $1 $2
    else
        sudo rsync -va $ArgR $Update --del --info=progress2 --exclude "VirtualBox VMs" --exclude "wine" $1 $2
    fi
}

BackupRestore() {
    HDDName="LukeHDDWD"

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
               "$HOME/.osu/" "/media/$USER/$HDDName/BackupsP/Data/osu/")
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
