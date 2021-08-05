#!/bin/bash
export vblank_mode=0
export WINEPREFIX="$HOME/.osu/wine"
export WINEARCH="win32"

. /etc/os-release
[[ $ID == arch ]] && export PATH=$HOME/.local/share/lutris/runners/wine/lutris-6.1-3-x86_64/bin:$PATH

drirc='
<device screen="0" driver="dri2">
    <application name="Default">
        <option name="vblank_mode" value="0"/>
    </application>
</device>
'

changeres() {
    if [[ $USER == lukee ]]; then
        if [[ $(xrandr | grep -c 'HDMI-1-1') == 1 ]]; then
            [[ $(xrandr | grep -c 'HDMI-1-1 connected') == 1 ]] && output=HDMI-1-1 || output=eDP-1-1
        elif [[ $(xrandr | grep -c 'HDMI-1') == 1 ]]; then
            [[ $(xrandr | grep -c 'HDMI-1 connected') == 1 ]] && output=HDMI-1 || output=eDP-1
        fi
        echo $output
        [[ $1 == 900 ]] && res="1440x900" || res="1920x1080"
        if [[ $res == 1440x900 ]]; then
            xrandr --output $output --mode $res --rate 74.98 2>/dev/null
            [ $? == 1 ] && xrandr --output $output --mode 1440x900 2>/dev/null
        elif [[ $res == 1920x1080 ]]; then
            xrandr --output $output --mode $res 2>/dev/null
        fi
    fi
}

oss() {
    #changeres 900
    qdbus org.kde.KWin /Compositor suspend
    xmodmap -e 'keycode 79 = q 7'
    xmodmap -e 'keycode 90 = space 0'
    if [[ $1 == "lazer" ]]; then
        $HOME/.osu/osu.AppImage
    else
        echo "$drirc" > $HOME/.drirc
        wineserver -k
        cd $HOME/.osu
        wine osu!.exe "$@"
        wineserver -k
        rm -f $HOME/.drirc
    fi
    setxkbmap -layout us
    qdbus org.kde.KWin /Compositor resume
    #changeres
}

random() {
    mapno=$1
    [[ ! $1 ]] && mapno=4
    cd $HOME/.osu
    for i in $(seq 1 $mapno); do
        wine osu!.exe "$HOME/.osu/oss/$(ls $HOME/.osu/oss/ | shuf -n 1)"
    done
}

remove() {
    ls $HOME/.osu/oss/ | sed -e 's/\.osz$//' | tee osslist
    ls $HOME/.osu/Songs | tee osulist
    ossremoved=$(comm -12 osslist osulist)
    sed 's/$/.osz/' $ossremoved
    sed 's/^/oss\//' $ossremoved
    cat $ossremoved | xargs -d '\n' rm -rf
    rm -f osslist osulist
    cat $ossremoved
}

update() {
    cd $HOME/.osu
    osuapi=$(curl -s https://api.github.com/repos/ppy/osu/releases/latest)
    current=$(cat osu.AppImage.version 2>/dev/null)
    [[ ! $current ]] && current='N/A'
    latest=$(echo "$osuapi" | grep "tag_name" | cut -d : -f 2,3)
    echo "osu!lazer"
    echo "* Current version: $current"
    echo "* Latest version: $latest"
    if [[ $latest != $current ]]; then
        read -p "Continue to update? (y/N) " continue
        [[ $continue != y && $continue != Y ]] && exit
        rm -rf tmp
        mkdir tmp
        cd tmp
        echo "$osuapi" | grep "/osu.AppImage" | cut -d : -f 2,3 | tr -d \" | wget -nv --show-progress -i -
        [[ ! -e osu.AppImage ]] && echo "Update failed" && exit
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

osuinstall() {
    [[ ! -e /usr/local/bin/osu ]] && sudo ln -sf $(dirname $(type -p $0))/osu.sh /usr/local/bin/osu
    sudo chmod +x /usr/local/bin/osu
    mkdir -p $HOME/.osu/wine 2>/dev/null
    cd $HOME/.osu

    if [[ $ID == arch ]]; then
        sudo pacman -S --noconfirm --needed lib32-alsa-plugins lib32-gnutls lib32-libpulse lib32-libxcomposite winetricks
        cd $HOME/Programs
        [[ ! -e wine-lutris-6.1-3-x86_64.tar.xz ]] && curl -LO https://github.com/lutris/wine/releases/download/lutris-6.1-3/wine-lutris-6.1-3-x86_64.tar.xz -o $HOME/Programs
        if [[ ! -d $HOME/.local/share/lutris/runners/wine/lutris-6.1-3-x86_64 ]]; then
            mkdir -p $HOME/.local/share/lutris/runners/wine
            7z x $HOME/Programs/wine-lutris-6.1-3-x86_64.tar.xz
            tar xvf wine-lutris-6.1-3-x86_64.tar -C $HOME/.local/share/lutris/runners/wine
            rm -f wine-lutris-6.1-3-x86_64.tar
        fi
    fi
    if [[ -d $WINEPREFIX ]]; then
        read -p "osu wine folder detected! Delete and reinstall? (y/N) " Confirm
        if [[ $Confirm == y ]] || [[ $Confirm == Y ]]; then
            rm -rf $WINEPREFIX
            winetricks -q dotnet40 gdiplus
        fi
        Confirm=
    else
        winetricks -q dotnet40 gdiplus
    fi
    
    [[ ! -e /etc/security/limits.conf.bak ]] && sudo cp /etc/security/limits.conf /etc/security/limits.conf.bak
    printf "@audio - nice -20\n@audio - rtprio 99\n" | sudo tee /etc/security/limits.conf
    sudo usermod -aG audio $USER

    if [[ $ID != arch ]]; then
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

        mkdir $HOME/.config/pulse 2>/dev/null
        cp -R /etc/pulse/default.pa $HOME/.config/pulse/default.pa
        sed -i "s/load-module module-udev-detect.*/load-module module-udev-detect tsched=0 fixed_latency_range=yes/" $HOME/.config/pulse/default.pa
    fi

    : '
    cat > /tmp/dsound.reg << "EOF"
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Wine\DirectSound]
"HelBuflen"="512"
"SndQueueMax"="3"
EOF
    wine regedit /tmp/dsound.reg'
    
    read -p "Preparations complete. Download and install osu! now? (y/N) " Confirm
    if [[ $Confirm == y ]] || [[ $Confirm == Y ]]; then
        curl -L 'https://m1.ppy.sh/r/osu!install.exe' -o osuinstall.exe
        wine "osuinstall.exe"
    fi
    cd $HOME
    ln -sf $HOME/.osu osu
    echo "Install script done"
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
    rm -f $HOME/.drirc
    qdbus org.kde.KWin /Compositor resume
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
    osuinstall
else
    oss "$@"
fi
