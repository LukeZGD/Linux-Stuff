#!/bin/bash

PROGDIR="$HOME/.wine/drive_c/Program Files/Genshin Impact"
BASEDIR="$HOME/Programs/Genshin Impact"
GAMEDIR="$BASEDIR/Genshin Impact game"
GIOLDIR="$BASEDIR/GI-on-Linux"
UPDATER="$GIOLDIR/updater/update_gi.sh"

Patch() {
    cd "$GIOLDIR"
    Version=$(ls -d 2*/ | cut -c 1-3 | sort -n | tail -n 1)
    Current=$(sed -n 's/^game_version=\(.*\)/\1/p' "$GAMEDIR/config.ini" | tr -d "\r\n" | tr -d '.')
    
    chmod +x $Version/*.sh
    cd "$GAMEDIR"
    if [[ $1 == install ]]; then
        if [[ $Version != $Current ]]; then
            echo
            echo "There is a newer version available!"
            echo "  Your current version is: $Current"
            echo "    The latest version is: $Version"
            echo
            echo "Make sure that the game is updated via the launcher before proceeding!"
            exit 1
        fi
        "$GIOLDIR"/$Version/patch.sh
        "$GIOLDIR"/$Version/patch_anti_logincrash.sh
    elif [[ $1 == uninstall ]]; then
        "$GIOLDIR"/$Version/patch_revert.sh
    fi
    cd "$BASEDIR"
}

Updater() {
    if [[ $1 == launcher ]]; then
        Patch uninstall
        wine "$BASEDIR/launcher.exe"
    elif [[ $1 == script ]]; then
        chmod +x "$UPDATER"
        "$UPDATER"
        read -s
    fi
}

Game() {
    qdbus org.kde.KWin /Compositor suspend
    Patch install
    cd "$GAMEDIR"
    res=$(xrandr --current | grep  '*' | uniq | awk '{print $1}' | tail -n1)
    wine explorer /desktop=anyname,$res cmd /c launcher.bat
    qdbus org.kde.KWin /Compositor resume
    running=0
}

Main() {
    running=1
    
    if [[ ! $(ping -c1 1.1.1.1 2>/dev/null) ]]; then
        echo "Please check your Internet connection before proceeding."
        exit 1
    fi
    
    if [[ ! -d "$GIOLDIR" ]]; then
        cd "$BASEDIR"
        git clone https://notabug.org/Krock/GI-on-Linux
    else
        cd "$GIOLDIR"
        git reset --hard
        git pull 2>/dev/null
    fi
    
    ln -sf "$BASEDIR" "$PROGDIR"
    cd "$GAMEDIR"
    
    while [[ $running == 1 ]]; do
        clear
        echo "Genshin Impact"
        select opt in "Launch Game" "Open Launcher for Updating" "Updater Script" "Install Patch" "Uninstall Patch"; do
        case $opt in
            "Launch Game" ) Game; break;;
            "Open Launcher for Updating" ) Updater launcher; break;;
            "Updater Script" ) Updater script; break;;
            "Install Patch" ) Patch install; read -s; break;;
            "Uninstall Patch" ) Patch uninstall; read -s; break;;
            * ) exit;;
        esac
        done
    done
}

Main
