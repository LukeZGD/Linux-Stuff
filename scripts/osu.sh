#!/bin/bash
osupath="$HOME/osu-stable"
osupathlazer="$HOME/.local/share/osu"
export WINEPREFIX="$osupath/prefix"
. /etc/os-release
#export vblank_mode=0
#export WINEARCH=win32
#export WINEFSYNC=1
#. $HOME/Linux-Stuff/scripts/preparelutris.sh
#preparelutris "$lutrisver"

osugame() {
    if [[ $1 != "stable" ]]; then
        env APPIMAGELAUNCHER_DISABLE=TRUE "$osupathlazer"/osu.AppImage
        return
    fi
    pushd "$osupath"
    wine "osu!.exe" "$@"
    popd
}

update() {
    cd "$osupathlazer"
    echo "osu!lazer"
    echo "Checking for updates..."
    osuapi=$(curl -s https://api.github.com/repos/ppy/osu/releases/latest)
    current=$(cat osu.AppImage.version)
    [[ ! $current ]] && current='N/A'
    latest=$(echo "$osuapi" | jq -j '.tag_name')
    url=$(echo "$osuapi" | jq -j '.assets[] | select(.name == "osu.AppImage") | .browser_download_url')
    echo "* Your current version is: $current"
    echo "* The latest version is:   $latest"
    if [[ $latest != $current ]]; then
        echo "There is a newer version available!"
        read -p "Continue to update? (Y/n) " continue
        [[ $continue == 'N' || $continue == 'n' ]] && exit
        rm -rf tmp
        mkdir tmp
        cd tmp
        if [[ -e ../osu.AppImage.aria2 ]]; then
            mv ../osu.AppImage.aria2 .
            mv ../osu.AppImage.tmp osu.AppImage
        fi
        aria2c $url
        if [[ -e osu.AppImage.aria2 ]]; then
            echo "Update failed"
            echo "Run the update again to continue download"
            mv osu.AppImage.aria2 ..
            mv osu.AppImage ../osu.AppImage.tmp
            exit 1
        fi
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
    ln -sf $HOME/Linux-Stuff/scripts/osu.sh /usr/local/bin/osu
    pushd "$osupath"
    if [[ -d $WINEPREFIX ]]; then
        read -p "osu wineprefix detected! Delete and reinstall? (y/N) " opt
        if [[ $opt == y || $opt == Y ]]; then
            rm -rf $WINEPREFIX
        fi
        opt=
    fi
    winetricks -q dotnet40
    wine reg add 'HKEY_CURRENT_USER\Control Panel\Desktop' /t REG_DWORD /v LogPixels /d 120 /f
    read -p "Preparations complete. Download and install osu! now? (y/N) " opt
    if [[ $opt == y || $opt == Y ]]; then
        curl -L 'https://m1.ppy.sh/r/osu!install.exe' -o osuinstall.exe
        wine "osuinstall.exe"
    fi
    popd
    echo "Install script done"
}

if [[ $1 == "update" ]]; then
    update
elif [[ $1 == "stable" ]]; then
    osugame stable
elif [[ $1 == "kill" ]]; then
    wineserver -k
elif [[ $1 == "help" ]]; then
    echo "Usage: $0 <operation> [...]"
    echo "Operations:
    osu {help}
    osu {install}
    osu {kill}
    osu {stable}
    osu {update}"
elif [[ $1 == "install" ]]; then
    osuinstall
else
    osugame "$@"
fi
