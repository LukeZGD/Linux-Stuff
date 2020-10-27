#!/bin/bash
export WINEPREFIX="$HOME/.wine_osu"
export WINEARCH="win32"

drirc='
<device screen="0" driver="dri2">
    <application name="Default">
        <option name="vblank_mode" value="0"/>
    </application>
</device>
'
[[ $USER == lukee ]] && outputs=(DVI-I-1 VGA-1 VGA-0 eDP1 eDP-1 eDP-1-1 HDMI1 HDMI-1 HDMI-1-1)

function changeres {
    [[ $1 == 900 ]] && res="1440x900" || res="1920x1080"
    for output in "${outputs[@]}"; do
        xrandr --output $output --mode $res --rate 74.98 2>/dev/null
        [ $? == 1 ] && xrandr --output $output --mode $res 2>/dev/null
    done
}

function oss {
    changeres 900
    if [[ $1 == "lazer" ]]; then
        $HOME/osu/osu.AppImage
    else
        echo "$drirc" > $HOME/.drirc
        wineserver -k
        cd $HOME/osu
        wine osu!.exe "$@"
        wineserver -k
        rm -f $HOME/.drirc
    fi
    changeres
}

function random {
    mapno=$1
    [[ ! $1 ]] && mapno=4
    cd $HOME/osu
    for i in $(seq 1 $mapno); do
        wine osu!.exe "$HOME/osu/oss/$(ls $HOME/osu/oss/ | shuf -n 1)"
    done
}

function remove {
    ls $HOME/osu/oss/ | sed -e 's/\.osz$//' | tee osslist
    ls $HOME/osu/Songs | tee osulist
    ossremoved=$(comm -12 osslist osulist)
    sed 's/$/.osz/' $ossremoved
    sed 's/^/oss\//' $ossremoved
    cat $ossremoved | xargs -d '\n' rm -rf
    rm -f osslist osulist
    cat $ossremoved
}

function update {
    cd $HOME/osu
    osuapi=$(curl -s https://api.github.com/repos/ppy/osu/releases/latest)
    current=$(cat osu.AppImage.version 2>/dev/null)
    [ ! $current ] && current='N/A'
    latest=$(echo "$osuapi" | grep "tag_name" | cut -d : -f 2,3)
    echo "osu!lazer"
    echo "* Current version: $current"
    echo "* Latest version: $latest"
    if [[ $latest != $current ]]; then
        read -p "Continue to update? (y/N) " continue
        [[ $continue != y ]] && [[ $continue != Y ]] && exit
        mkdir tmp 2>/dev/null
        cd tmp
        echo "$osuapi" | grep "/osu.AppImage" | cut -d : -f 2,3 | tr -d \" | wget -nv --show-progress -i -
        [ ! -e osu.AppImage ] && echo "Update failed" && exit
        rm -f ../osu.AppImage*
        mv osu.AppImage* ..
        cd ..
        rm -rf tmp
        chmod +x osu.AppImage
        echo "$latest" > osu.AppImage.version
        echo "Updated osu!lazer to $latest"
    else
        echo "Currently updated, nothing to do"
    fi
    echo "Press ENTER to exit."
    read -s
}

function install {
    sudo cp /etc/security/limits.conf /etc/security/limits.conf.bak
    echo "@audio - nice -20
    @audio - rtprio 99" | sudo tee /etc/security/limits.conf
    sudo mkdir /etc/pulse/daemon.conf.d 2>/dev/null
    echo "high-priority = yes
    nice-level = -15

    realtime-scheduling = yes
    realtime-priority = 50

    resample-method = speex-float-0

    default-sample-format = s32le
    default-sample-rate = 48000
    alternate-sample-rate = 48000
    default-sample-channels = 2

    default-fragments = 2
    default-fragment-size-msec = 4" | sudo tee /etc/pulse/daemon.conf.d/10-better-latency.conf

    [ ! -e /usr/bin/osu ] && sudo cp $(dirname $(type -p $0))/osu.sh /usr/bin/osu
    sudo chmod +x /usr/bin/osu

    mkdir $HOME/.config/pulse 2>/dev/null
    cp -R /etc/pulse/default.pa $HOME/.config/pulse/default.pa
    sed -i "s/load-module module-udev-detect.*/load-module module-udev-detect tsched=0 fixed_latency_range=yes/" $HOME/.config/pulse/default.pa
    
    sudo pacman -S --noconfirm --needed lib32-alsa-plugins lib32-gnutls lib32-libpulse lib32-libxcomposite winetricks
    if [ -d $HOME/.wine_osu ]; then
        read -p "wine_osu folder detected! Delete and reinstall? (y/N) " Confirm
        if [[ $osuDL == y ]] || [[ $osuDL == Y ]]; then
            exit
        fi
    fi
    rm -rf $HOME/.wine_osu
    
    winetricks -q dotnet40 gdiplus
    
    mkdir $HOME/osu 2>/dev/null
    cd osu
    read -p "Preparations complete. Download and install osu! now? (y/N) " osuDL
    if [[ $osuDL == y ]] || [[ $osuDL == Y ]]; then
        curl -L 'https://m1.ppy.sh/r/osu!install.exe' -o osuinstall.exe
        wine "osuinstall.exe"
    fi
    echo "Script done"
}

if [[ $1 == "random" ]]; then
    random $2
elif [[ $1 == "remove" ]]; then
    remove
elif [[ $1 == "update" ]]; then
    update
elif [[ $1 == "lazer" ]]; then
    oss lazer
elif [[ $1 == "kill" ]]; then
    wineserver -k
    changeres
    exit
elif [[ $1 == "help" ]]; then
    echo "Usage: $0 <operation> [...]"
    echo "Operations:
    osu {help}
    osu {install}
    osu {kill}
    osu {lazer}
    osu {random} [no. of maps] (default=4)
    osu {remove}
    osu {update}"
elif [[ $1 == "install" ]]; then
    install
else
    oss "$@"
fi
