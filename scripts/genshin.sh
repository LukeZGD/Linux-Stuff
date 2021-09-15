#!/bin/bash

PROGDIR="$HOME/.wine/drive_c/Program Files/Genshin Impact"
BASEDIR="$HOME/Programs/Genshin Impact"
GAMEDIR="$BASEDIR/Genshin Impact game"
GIOLDIR="$BASEDIR/GI-on-Linux"
UPDATER="$GIOLDIR/updater/update_gi.sh"

GetVersions() {
    # from update_gi script
    UPDATE_URL="https://sdk-os-static.mihoyo.com/hk4e_global/mdk/launcher/api/resource?key=gcStgarh&launcher_id=10"
    game_element="game"
    end_element="plugin"
    update_content_src=$(curl -L "$UPDATE_URL" -o update_content && cat update_content* &>/dev/null)
    rm update_content
    update_content=$(sed "s/^.*\"$game_element\":{//;s/,\"$end_element\":.*$//;s/{/&\n/g;s/}/\n&/g" <<< "$update_content_src")
    latest_version_content=$(sed -n '/"latest":/,/^}/{/"version":/!d;s/,/\n/g;s/"//g;p}' <<< "$update_content")
    declare -A version_info
    while read -r keyvalue; do
        version_info[${keyvalue%%:*}]=${keyvalue#*:}
    done <<< "$latest_version_content"
    Current=$(sed -n 's/^game_version=\(.*\)/\1/p' "$GAMEDIR/config.ini" | tr -d "\r\n" | tr -d '.')
    Version=$(echo ${version_info[version]} | tr -d '.')
}

Patch() {
    cd "$GIOLDIR"
    GetVersions
    chmod +x $Current/*.sh $Version/*.sh
    cd "$GAMEDIR"
    if [[ $1 == install ]]; then
        if (( $Version > $Current )); then
            echo
            echo "There is a newer version available!"
            echo "* Your current version is: $Current"
            echo "* The latest version is:   $Version"
            echo
            echo "Make sure that the game is updated before proceeding!"
            read -s
            return 1
        fi
        "$GIOLDIR"/$Current/patch.sh
        "$GIOLDIR"/$Current/patch_anti_logincrash.sh
    elif [[ $1 == uninstall ]]; then
        "$GIOLDIR"/$Current/patch_revert.sh
    fi
    cd "$BASEDIR"
}

Updater() {
    if [[ $1 == launcher ]]; then
        Patch uninstall
        wine "$BASEDIR/launcher.exe"
    else
        chmod +x "$UPDATER"
        "$UPDATER" $1
        read -s
    fi
}

Game() {
    qdbus org.kde.KWin /Compositor suspend
    Patch install
    [[ $? != 0 ]] && return
    cd "$GAMEDIR"
    res=$(xrandr --current | grep '*' | uniq | awk '{print $1}' | tail -n1)
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
        select opt in "Launch Game" "Updater Script" "Install Patch" "Uninstall Patch" "(Any other key to exit)"; do
        case $opt in
            "Launch Game" ) Game; break;;
            "Updater Script" ) Updater; break;;
            "Install Patch" ) Patch install; read -s; break;;
            "Uninstall Patch" ) Patch uninstall; read -s; break;;
            * ) exit;;
        esac
        done
    done
}

Main
