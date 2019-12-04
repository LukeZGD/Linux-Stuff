#!/bin/bash

packages=(
ncurses5-compat-libs
python2-twodict-git
chromium-vaapi-bin
chromium-widevine
cydia-impactor
gallery-dl
github-desktop-bin
input-veikk-dkms
qdirstat
ttf-ms-fonts
ttf-tahoma
ttf-vista-fonts
uget-integrator
uget-integrator-browsers
vlc-plugin-fluidsynth
woeusb
youtube-dl
gui-git
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
libretro-shaders-slang
libretro-snes9x
retroarch
retroarch-assets-ozone
retroarch-assets-xmb
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
        sudo pacman -U --noconfirm AUR/$package/*.xz
    done
}

function vbox {
    sudo pacman -S --noconfirm virtualbox virtualbox-host-dkms virtualbox-guest-iso
    sudo pacman -U --noconfirm AUR/virtualbox-ext-oracle/*.xz
    sudo usermod -aG vboxusers $SUDO_USER
    sudo modprobe vboxdrv
}

function laptop {
    sudo pacman -S --noconfirm nvidia-dkms nvidia-settings bbswitch-dkms tlp
    sudo pacman -U --noconfirm AUR/optimus-manager/*.xz
    sudo pacman -U --noconfirm AUR/optimus-manager-qt/*.xz
}

function 390xx {
    sudo pacman -S --noconfirm nvidia-390xx-dkms nvidia-390xx-settings
}

function emulatorsinstall {
    sudo pacman -S --noconfirm ${emulators[*]}
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
    sudo pacman -U --noconfirm wine-osu-3.12-2-x86_64.pkg.tar.xz

    cp -R dotcache/winetricks /home/lukee/.cache

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

# ----------------------------------

clear
echo "LukeZGD Arch Post-Install Script"
echo
select opt in "Local AUR pkgs" "VirtualBox" "NVIDIA Optimus" "NVIDIA 390xx" "osu!" "Emulators"; do
    case $opt in
        "Local AUR pkgs" ) postinstall; break;;
        "VirtualBox" ) vbox; break;;
        "NVIDIA Optimus" ) laptop; break;;
        "NVIDIA 390xx" ) 390xx; break;;
        "osu!" ) osu; break;;
        "Emulators" ) emulatorsinstall; break;;
    esac
done
