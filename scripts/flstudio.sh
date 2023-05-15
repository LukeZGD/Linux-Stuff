#!/bin/bash
. $HOME/Arch-Stuff/scripts/preparelutris.sh
preparelutris "fshack-6.21-6" "d27a7a23d1081b8090ee5683e59a99519dd77ef0"
export WINEPREFIX=$HOME/.wine_fl

fl32() {
    cd "$WINEPREFIX/dosdevices/c:/Program Files/Image-Line/FL Studio 20"
    wine C:\\windows\\command\\start.exe /Unix $WINEPREFIX/dosdevices/c:/users/$USER/Start\ Menu/Programs/Image-Line/FL\ Studio\ 20\ \(32bit\).lnk
}

fl64() {
    cd "$WINEPREFIX/dosdevices/c:/Program Files/Image-Line/Shared"
    wine C:\\users\\Public\\Desktop\\FL\ Studio\ 20.lnk
}

kill() {
    wineserver -k
}

install() {
    echo "this will remove the existing fl wineprefix. continuing in 5s."
    sleep 5
    rm -rf $WINEPREFIX
    wine reg add 'HKEY_CURRENT_USER\Control Panel\Desktop' /t REG_DWORD /v LogPixels /d 120 /f
    cd "$WINEPREFIX/drive_c/Program Files (x86)/"
    ln -sf "../Program Files/Image-Line/" .
    mkdir -p "$WINEPREFIX/drive_c/users/$USER/Start Menu/Programs/Image-Line/"
    cp "$HOME/Documents/FL Studio 20 (32bit).lnk" "$WINEPREFIX/drive_c/users/$USER/Start Menu/Programs/Image-Line/"
    echo "prepared wineprefix"
    cd $HOME

    setup="$(zenity --file-selection --file-filter='exe | *.exe' --title="Select setup exe")"
    [[ -z "$setup" ]] && exit 1
    patch="$(zenity --file-selection --file-filter='exe | *.exe' --title="Select patch exe")"
    [[ -z "$patch" ]] && exit 1
    wine "$setup"
    wine "$patch"
}

if [[ ! $* ]]; then
    echo "no arguments"
    exit 1
fi
$1 "$@"
