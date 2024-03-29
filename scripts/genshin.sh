#!/bin/bash
trap 'wineserver -k; exit' INT TERM EXIT

export WINEFSYNC=1
BASEDIR="/mnt/Data/GamesS/Genshin Impact"
export WINEPREFIX="$BASEDIR/prefix"
export DXVK_ASYNC=1
PROGDIR="$WINEPREFIX/drive_c/Program Files/Genshin Impact"
GAMEDIR="$BASEDIR/Genshin Impact game"
GIOLDIR="$BASEDIR/dawn"
UPDATER="$GIOLDIR/updater/update_gi.sh"
defaultres="1920x1080"
if [[ $(lspci | grep -E "VGA|3D" | grep -c NVIDIA) != 0 ]]; then
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
fi

. $HOME/Linux-Stuff/scripts/preparelutris.sh
preparelutris "$lutrisver"
if [[ ! -d "$WINEPREFIX" ]]; then
    preparewineprefix "$WINEPREFIX"
    winetricks -q corefonts win10
fi
#export DXVK_HUD=version,devinfo,fps

GetVersions() {
    # from update_gi script
    UPDATE_URL="https://sdk-os-static.mihoyo.com/hk4e_global/mdk/launcher/api/resource?key=gcStgarh&launcher_id=10"
    game_element="game"
    end_element="plugin"
    update_content_src=$(curl -L "$UPDATE_URL" -o update_content >/dev/null && cat update_content* 2>/dev/null)
    rm update_content
    update_content=$(sed "s/^.*\"$game_element\":{//;s/,\"$end_element\":.*$//;s/{/&\n/g;s/}/\n&/g" <<< "$update_content_src")
    latest_version_content=$(sed -n '/"latest":/,/^}/{/"version":/!d;s/,/\n/g;s/"//g;p}' <<< "$update_content")
    declare -A version_info
    while read -r keyvalue; do
        version_info[${keyvalue%%:*}]=${keyvalue#*:}
    done <<< "$latest_version_content"
    Current=$(sed -n 's/^game_version=\(.*\)/\1/p' "$GAMEDIR/config.ini" | tr -d "\r\n.")
    Version=$(echo ${version_info[version]} | tr -d '.')
}

Patch() {
    cd "$GIOLDIR"
    GetVersions
    chmod +x $Current/*.sh $Version/*.sh
    cd "$GAMEDIR"
    if [[ $1 == "install" ]]; then
        if (( Version > Current )); then
            Current=$(echo $Current | sed 's/./&./2;s/./&./1')
            Version=$(echo $Version | sed 's/./&./2;s/./&./1')
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
    elif [[ $1 == "uninstall" ]]; then
        "$GIOLDIR"/$Current/patch_revert.sh
    fi
    cd "$BASEDIR"
}

Updater() {
    cd "$GAMEDIR"
    chmod +x "$UPDATER"
    "$UPDATER" $1 nodelete
    read -s
}

Game() {
    qdbus org.kde.KWin /Compositor suspend
    #Patch install
    [[ $? != 0 ]] && return
    cd "$GAMEDIR"
    res=$(xrandr --current | grep '*' | uniq | awk '{print $1}' | tail -n1)
    [[ -z $res ]] && res="$defaultres"
    #wine explorer /desktop=anyname,$res GenshinImpact.exe
    wine GenshinImpact.exe
    qdbus org.kde.KWin /Compositor resume
    running=0
}

Install() {
    if [[ -d "$GIOLDIR" ]]; then
        cd "$GIOLDIR"
        GetVersions
        echo $Current
        if (( Current > 0 )); then
            echo "Game is already installed."
            read -s
            return
        fi
    fi
    read -p "Game folder will be removed and the full game will be (re-)installed. Continue? (y/N) " opt
    [[ $opt != 'y' && $opt != 'Y' ]] && return
    rm -rf "$GAMEDIR"
    mkdir "$GAMEDIR"
    Updater install
}

Dawn() {
    if [[ ! -d "$GIOLDIR" ]]; then
        cd "$BASEDIR"
        git clone https://notabug.org/Krock/dawn
    else
        cd "$GIOLDIR"
        if [[ $skip != 1 ]]; then
            git reset --hard
            git clean -fxd
            git pull
        fi
    fi
}

updatelauncher() {
    mkdir "$BASEDIR/tmp"
    pushd "$BASEDIR/tmp"
    aria2c https://sg-public-api.hoyoverse.com/event/download_porter/link/ys_global/genshinimpactpc/default
    wine "$BASEDIR/tmp/Genshin"*".exe"
    popd
    rm -rf "$BASEDIR/tmp"
}

Main() {
    running=1

    ping -c1 google.com >/dev/null
    if [[ $? != 0 ]]; then
        echo "Please check your Internet connection before proceeding."
        exit 1
    fi

    ln -sf "$BASEDIR" "$PROGDIR"
    cd "$GAMEDIR"
    
    while [[ $running == 1 ]]; do
        clear
        echo "Genshin Impact"
        select opt in "Launch Game" "Open Launcher" "Update Launcher" "Kill Wineserver" "Open Base Directory" "(Any other key to exit)"; do
        case $opt in
            "Launch Game" ) Game; break;;
            "Update Game" ) Updater; break;;
            "Pre-Installation" ) Updater predownload; break;;
            "Install Patch" ) Patch install; read -s; break;;
            "Uninstall Patch" ) Patch uninstall; read -s; break;;
            "Update Patch" ) Dawn; break;;
            "(Re-)Install Game" ) Install; break;;
            "Delete Update Files" ) rm "$BASEDIR/_update_gi_download/"*; break;;
            "Kill Wineserver" ) wineserver -k; break;;
            "Open Launcher" ) wine "$BASEDIR/launcher.exe"; break;;
            "Open Base Directory" ) dolphin "$BASEDIR"; break;;
            "Update Launcher" ) updatelauncher; break;;
            * ) running=0; break;;
        esac
        done
    done
}

Main
