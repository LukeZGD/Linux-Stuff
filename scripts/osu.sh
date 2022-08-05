#!/bin/bash
export vblank_mode=0
export WINEPREFIX="$HOME/.wine_osu"
export WINEARCH="win32"
osupath="$HOME/.osu"
. /etc/os-release
. $HOME/Arch-Stuff/scripts/preparelutris.sh
preparelutris "$lutrisver" "$lutrissha1"

osugame() {
    if [[ $1 == "lazer" ]]; then
        env APPIMAGELAUNCHER_DISABLE=TRUE "$osupath"/osu.AppImage
        return
    fi

    qdbus org.kde.KWin /Compositor suspend
    [[ -z "$*" ]] && wineserver -k
    cd "$osupath"
    wine osu!.exe "$@" |& tee "$osupath"/Logs/osulog1
    wineserver -w
    [[ -d _pending ]] && wine osu!.exe "$@" |& tee "$osupath"/Logs/osulog2
    wineserver -w
    if [[ -d _cleanup && ! -e osu!.exe ]]; then
        local current
        local latest=0
        local latestfile
        echo "osu!.exe is missing. finding latest .exe in _cleanup..."
        for file in _cleanup/*; do
            if [[ $(file "$file" | grep -c Windows) ]]; then
                current=$(date -r $file +%s) # date modified in unix time
                echo "found: $file - $current"
                if (( current > latest )); then
                    latest=$current
                    latestfile="$file"
                    echo "latest: $file - $latest"
                fi
            fi
        done
        echo "latest file found: $latestfile"
        echo "copying"
        cp "$latestfile" osu!.exe
        echo "done"
    fi
    [[ -d _cleanup ]] && wine osu!.exe "$@" |& tee "$osupath"/Logs/osulog3
    wineserver -w
    qdbus org.kde.KWin /Compositor resume
}

random() {
    mapno=$1
    [[ ! $1 ]] && mapno=4
    cd "$osupath"
    for i in $(seq 1 $mapno); do
        wine osu!.exe "$osupath/oss/$(ls "$osupath"/oss/ | shuf -n 1)"
    done
}

remove() {
    ls "$osupath"/oss/ | sed -e 's/\.osz$//' | tee osslist
    ls "$osupath"/Songs | tee osulist
    local ossremoved=$(comm -12 osslist osulist)
    sed 's/$/.osz/' $ossremoved
    sed 's/^/oss\//' $ossremoved
    cat $ossremoved | xargs -d '\n' rm -rf
    rm -f osslist osulist
    cat $ossremoved
}

update() {
    cd "$osupath"
    osuapi=$(curl -s https://api.github.com/repos/ppy/osu/releases/latest)
    current=$(cat osu.AppImage.version 2>/dev/null)
    [[ ! $current ]] && current='N/A'
    latest=$(echo "$osuapi" | grep "tag_name" | cut -d : -f 2,3)
    echo "osu!lazer"
    echo "* Your current version is: $current"
    echo "* The latest version is:   $latest"
    if [[ $latest != $current ]]; then
        echo "There is a newer version available!"
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
    sudo ln -sf $HOME/Arch-Stuff/scripts/osu.sh /usr/local/bin/osu
    sudo chmod +x /usr/local/bin/osu
    cd "$osupath"

    if [[ $ID == arch ]]; then
        pac install aria2 lib32-alsa-plugins lib32-gnutls lib32-libpulse lib32-libxcomposite winetricks
    fi

    if [[ -d $WINEPREFIX ]]; then
        read -p "osu wine folder detected! Delete and reinstall? (y/N) " Confirm
        if [[ $Confirm == y || $Confirm == Y ]]; then
            rm -rf $WINEPREFIX
        fi
        Confirm=
    fi
    winetricks -q dotnet40 gdiplus
    wine reg add 'HKEY_CURRENT_USER\Control Panel\Desktop' /t REG_DWORD /v LogPixels /d 120 /f

    read -p "Preparations complete. Download and install osu! now? (y/N) " Confirm
    if [[ $Confirm == y || $Confirm == Y ]]; then
        curl -L 'https://m1.ppy.sh/r/osu!install.exe' -o osuinstall.exe
        wine "osuinstall.exe"
    fi
    cd $HOME
    ln -sf "$osupath" osu
    echo "Install script done"
}

if [[ $1 == "random" ]]; then
    random $2
elif [[ $1 == "remove" ]]; then
    remove
elif [[ $1 == "update" ]]; then
    update
elif [[ $1 == "lazer" ]]; then
    osugame lazer
elif [[ $1 == "kill" ]]; then
    wineserver -k
    qdbus org.kde.KWin /Compositor resume
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
    osugame "$@"
fi
