#!/bin/bash

PROGDIR="$HOME/.wine/drive_c/Program Files/Genshin Impact"
BASEDIR="$HOME/Programs/Genshin Impact"
GAMEDIR="$BASEDIR/Genshin Impact game"
GIOLDIR="$BASEDIR/GI-on-Linux"

Main() {
    qdbus org.kde.KWin /Compositor suspend
    ln -sf "$BASEDIR" "$PROGDIR"
    clear
    echo "Genshin Impact"
    select opt in "Launch Game" "Open Launcher for Updating" "Install Patch" "Uninstall Patch"; do
        case $opt in
            "Launch Game" ) Patch install; cd "$GAMEDIR"; wine explorer /desktop=anyname,1920x1080 cmd /c launcher.bat; break;;
            "Open Launcher for Updating" ) Patch uninstall; cd "$GAMEDIR"; wine "$BASEDIR/launcher.exe"; break;;
            "Install Patch" ) Patch install; break;;
            "Uninstall Patch" ) Patch uninstall; break;;
            * ) exit;;
        esac
    done
    qdbus org.kde.KWin /Compositor resume
}

Patch() {
    if [[ ! -d "$GIOLDIR" ]]; then
        cd "$BASEDIR"
        git clone https://notabug.org/Krock/GI-on-Linux
    else
        cd "$GIOLDIR"
        git reset --hard
        git pull
    fi
    cd "$GIOLDIR"
    Version=$(ls -d 1*/ | cut -c 1-3 |sort -n | tail -n 1)
    Current=$(cat "$BASEDIR"/gi-on-linux-version)
    
    # Uncomment below for spoof
    #Version=$Current
    
    chmod +x $Version/*.sh
    cd "$GAMEDIR"
    if [[ $1 == install ]]; then
        if [[ $Version != $Current ]]; then
            echo
            echo "There is a newer version available!!"
            echo "  Your current version is: $Current"
            echo "    The latest version is: $Version"
            echo
            echo "Make sure that the game is updated via the launcher before proceeding!!"
            echo "Press Ctrl+C to cancel, press ENTER to continue"
            read -s
        fi
        "$GIOLDIR"/$Version/patch.sh
        "$GIOLDIR"/$Version/patch_anti_logincrash.sh
    elif [[ $1 == uninstall ]]; then
        "$GIOLDIR"/$Version/patch_revert.sh
    fi
    cd "$BASEDIR"
    echo $Version | tee gi-on-linux-version
}

Main
