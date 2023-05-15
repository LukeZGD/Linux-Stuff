#!/bin/bash
lutrisver="GE-Proton7-43"
protonver="GE-Proton7-55"
lutris="lutris-$lutrisver-x86_64"
lutrispath="$HOME/.local/share/lutris/runners/wine"

preparewineprefix() {
    [[ -n $1 ]] && export WINEPREFIX=$1 || export WINEPREFIX=$HOME/.wine
    [[ -n $2 ]] && export WINEARCH=$2 || export WINEARCH=win64
    wine reg add 'HKEY_CURRENT_USER\Control Panel\Desktop' /t REG_DWORD /v LogPixels /d 120 /f
    wine reg add 'HKEY_CURRENT_USER\Software\Wine\DllOverrides' /t REG_SZ /v dsdmo /f
    cd $WINEPREFIX/drive_c
    rm -rf ProgramData
    ln -sf $HOME/AppData ProgramData
    cd $WINEPREFIX/drive_c/users/$USER
    rm -rf AppData 'Application Data' 'Saved Games'
    ln -sf $HOME/AppData
    ln -sf $HOME/AppData 'Application Data'
    ln -sf $HOME/AppData 'Saved Games'
}

preparelutris() {
    lutrisver="$1"
    lutris="lutris-$lutrisver-x86_64"
    lutrispath="$HOME/.local/share/lutris/runners/wine"
    lutrissha1="$2"
    if [[ $lutrisver == *"5."* ]]; then
        lutrislink="https://lutris.nyc3.cdn.digitaloceanspaces.com/runners/wine/wine-$lutris"
    elif [[ $lutrisver == *"6."* ]]; then
        lutrislink="https://github.com/lutris/wine/releases/download/lutris-$(echo $lutrisver | cut -c 8-)/wine-$lutris"
        lutrispath+="2"
    elif [[ $lutrisver == "GE"* ]]; then
        lutrislink="https://github.com/GloriousEggroll/wine-ge-custom/releases/download/$lutrisver/wine-$lutris"
    else
        lutrislink="https://github.com/lutris/wine/releases/download/lutris-wine-$lutrisver/wine-$lutris"
    fi
    mkdir -p $lutrispath 2>/dev/null
    export PATH=$lutrispath/$lutris/bin:$PATH

    cd $HOME/Programs

    if [[ $lutrissha1 == "proton" ]]; then
        lutrislink="https://github.com/GloriousEggroll/proton-ge-custom/releases/download/$lutrisver/$lutrisver"
        if [[ ! -e $lutrisver.tar.gz || -e $lutrisver.tar.gz.aria2 ]]; then
            aria2c "$lutrislink.tar.gz"
        fi
        if [[ ! -e $lutrisver.sha512sum ]]; then
            curl -LO "$lutrislink.sha512sum"
        fi
        sha512sum -c $lutrisver.sha512sum
        if [[ $? != 0 ]]; then
            echo "wine proton $lutrisver verifying failed"
            [[ ! -e $lutris.tar.gz.aria2 ]] && rm -f $lutris.tar.gz
            exit 1
        fi
        lutrispath+="2"
        if [[ ! -d $lutrispath/$lutrisver ]]; then
            tar -xzvf $lutrisver.tar -C $lutrispath
        fi
        return
    fi

    if [[ ! -e wine-$lutris.tar.xz || -e wine-$lutris.tar.xz.aria2 ]]; then
        aria2c "$lutrislink.tar.xz"
    fi

    if [[ $lutrisver == "GE"* ]]; then
        if [[ ! -e wine-$lutris.sha512sum ]]; then
            curl -LO "$lutrislink.sha512sum"
        fi
        sha512sum -c wine-$lutris.sha512sum
        if [[ $? != 0 ]]; then
            echo "wine lutris $lutrisver verifying failed"
            [[ ! -e wine-$lutris.tar.xz.aria2 ]] && rm -f wine-$lutris.tar.xz
            exit 1
        fi
    else
        lutrissha1L=$(shasum wine-$lutris.tar.xz | awk '{print $1}')
        if [[ $lutrissha1L != $lutrissha1 ]]; then
            echo "wine lutris $lutrisver verifying failed"
            echo "expected $lutrissha1, got $lutrissha1L"
            [[ ! -e wine-$lutris.tar.xz.aria2 ]] && rm -f wine-$lutris.tar.xz
            exit 1
        fi
    fi

    if [[ ! -d $lutrispath/$lutris ]]; then
        mkdir -p $lutrispath
        7z x wine-$lutris.tar.xz
        tar xvf wine-$lutris.tar -C $lutrispath
        rm -f wine-$lutris.tar
    fi
}
