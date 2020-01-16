#!/bin/bash

packages=(
libsndio-61-compat
ncurses5-compat-libs
python2-twodict-git
adwaita-qt
chromium-vaapi-bin
chromium-widevine
gallery-dl
github-desktop-bin
qdirstat
uget-integrator
uget-integrator-browsers
woeusb
wps-office
youtube-dl-gui-git
yay-bin
)

emulators=(
dolphin-emu
pcsx2
libretro-beetle-psx-hw
libretro-bsnes
libretro-citra
libretro-core-info
libretro-desmume
libretro-gambatte
libretro-melonds
libretro-mgba
libretro-mupen64plus-next
libretro-nestopia
libretro-overlays
libretro-ppsspp
libretro-snes9x
retroarch
retroarch-assets-ozone
)

osu='
#!/bin/sh
export WINEPREFIX="$HOME/.wine_osu"
export STAGING_AUDIO_DURATION=50000

# Arch Linux/wine-osu users should uncomment next line
# for the patch to be effective
export PATH=/opt/wine-osu/bin:$PATH

cd ~/osu # Or wherever you installed osu! in
wine osu!.exe "$@"
'

osukill='
#!/bin/sh
export WINEPREFIX="$HOME/.wine_osu"

wineserver -k
'

function postinstall {
    for package in "${packages[@]}"
    do
        sudo pacman -U --noconfirm ~/.cache/yay/$package/*.xz
    done
    sudo pacman -U --noconfirm ~/Documents/input-veikk-dkms*.xz ~/Documents/ttf-ms-win10/*
}

function postinstallyay {
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    makepkg -si --noconfirm
    rm -rf yay-bin
    for package in "${packages[@]}"
    do
        yay --noconfirm $package
    done
    sudo pacman -U --noconfirm ~/Documents/input-veikk-dkms*.xz  ~/Documents/ttf-ms-win10/*
}

function vbox {
    sudo pacman -S --noconfirm virtualbox virtualbox-host-dkms virtualbox-guest-iso
    sudo pacman -U --noconfirm ~/.cache/yay/virtualbox-ext-oracle/*.xz
    sudo usermod -aG vboxusers $SUDO_USER
    sudo modprobe vboxdrv
}

function laptop {
    sudo pacman -S --noconfirm nvidia-dkms nvidia-settings bbswitch-dkms tlp
    sudo pacman -U --noconfirm AUR/optimus-manager/*.xz
    sudo pacman -U --noconfirm AUR/optimus-manager-qt/*.xz
    sudo systemctl enable tlp
}

function 390xx {
    sudo pacman -S --noconfirm nvidia-390xx-dkms nvidia-390xx-settings
}

function emulatorsinstall {
    sudo pacman -S --noconfirm ${emulators[*]}
    sudo pacman -U --noconfirm AUR/cemu/*.xz
}

function osu {
    sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
    sudo pacman -Sy

    cd osuscript
    sudo cp -R /etc/security/limits.conf /etc/security/limits.conf.bak
    echo "@audio - nice -20
    @audio - rtprio 99 " | sudo tee /etc/security/limits.conf

    sudo mkdir /etc/pulse/daemon.conf.d
    echo "high-priority = yes
    nice-level = -15

    realtime-scheduling = yes
    realtime-priority = 50

    resample-method = speex-float-0

    default-fragments = 2 # Minimum is 2
    default-fragment-size-msec = 4" | sudo tee /etc/pulse/daemon.conf.d/10-better-latency.conf

    echo "$osu" | sudo tee /usr/bin/osu
    echo "$osukill" | sudo tee /usr/bin/osukill
    sudo chmod +x /usr/bin/osu
    sudo chmod +x /usr/bin/osukill

    sink="$(pacmd info |grep 'Default sink name' |cut -c 20-)"

    mkdir ~/.config/pulse
    cp -R /etc/pulse/default.pa ~/.config/pulse/default.pa
    sudo sed -i "s/load-module module-udev-detect.*/load-module module-udev-detect tsched=0 fixed_latency_range=yes/" ~/.config/pulse/default.pa
    echo "load-module module-null-sink sink_name=\"audiocap\" sink_properties=device.description=\"audiocap\"
    load-module module-loopback latency_msec=1 sink=\"audiocap\" source=\"$sink.monitor\"" | sudo tee -a ~/.config/pulse/default.pa

    echo "390xx or nah (y/n)"
    read sel
    if [ $sel == y ]
    then
        sudo pacman -S --noconfirm lib32-nvidia-390xx-utils
    fi
    echo "nvidia or nah (y/n)"
    read nvidia
    if [ $nvidia == y ]
    then
        sudo pacman -S --noconfirm lib32-nvidia-utils
    fi
    sudo pacman -S --noconfirm winetricks lib32-libxcomposite lib32-gnutls
    sudo pacman -U --noconfirm ~/Documents/wine-osu*.xz

    sudo rsync -va --update --delete-after /run/media/$USER/LukeHDD/Backups/wine/ /home/$USER/.cache/yay/
    sudo rsync -va --update --delete-after /run/media/$USER/LukeHDD/Backups/winetricks/ /home/$USER/.cache/winetricks/

    export WINEPREFIX="$HOME/.wine_osu" # This is the path to a hidden folder in your home folder.
    export WINEARCH=win32 # Only needed when executing the first command with that WINEPREFIX
    export PATH=/opt/wine-osu/bin:$PATH

    winetricks dotnet40
    winetricks gdiplus
    winetricks cjkfonts

    rm -rf /home/lukee/.cache/winetricks
    echo "Preparations complete. Download and install osu! now? (y/n) (needs wget)"
    read installoss
    if [ $installoss == y ]
    then
        wget 'https://m1.ppy.sh/r/osu!install.exe'
        wine 'osu!install.exe'
    fi
    echo "Script done"
}

function devkitPro {
echo 'DEVKITPRO=/opt/devkitpro
DEVKITARM=/opt/devkitpro/devkitARM
DEVKITPPC=/opt/devkitpro/devkitPPC' | sudo tee -a /etc/environment
sudo pacman-key --recv F7FD5492264BB9D0
sudo pacman-key --lsign F7FD5492264BB9D0
sudo pacman -U https://downloads.devkitpro.org/devkitpro-keyring-r1.787e015-2-any.pkg.tar.xz
echo '[dkp-libs]
Server = https://downloads.devkitpro.org/packages
[dkp-linux]
Server = https://downloads.devkitpro.org/packages/linux' | sudo tee -a /etc/pacman.conf
sudo pacman -Sy 3ds-dev switch-dev
}

function rc-local {
echo '[Unit]
Description=/etc/rc.local compatibility

[Service]
Type=oneshot
ExecStart=/etc/rc.local
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target' | sudo tee /usr/lib/systemd/system/rc-local.service
sudo systemctl enable rc-local.service
echo '#!/bin/bash
echo 0,0,345,345 | sudo tee /sys/module/veikk/parameters/bounds_map
exit 0' | sudo tee /etc/rc.local
sudo chmod +x /etc/rc.local
}

# ----------------------------------

clear
echo "LukeZGD Arch Post-Install Script"
echo
select opt in 'Install AUR pkgs w/ yay' "Local AUR pkgs" "VirtualBox" "NVIDIA Optimus+TLP" "NVIDIA 390xx" "osu!" "Emulators" "devkitPro" "rc-local"; do
    case $opt in
        'Install AUR pkgs w/ yay' ) postinstallyay; break;;
        "Local AUR pkgs" ) postinstall; break;;
        "VirtualBox" ) vbox; break;;
        "NVIDIA Optimus+TLP" ) laptop; break;;
        "NVIDIA 390xx" ) 390xx; break;;
        "osu!" ) osu; break;;
        "Emulators" ) emulatorsinstall; break;;
        "devkitPro" ) devkitPro; break;;
        "rc-local" ) rc-local; break;;
    esac
done
