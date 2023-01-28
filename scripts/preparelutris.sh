#!/bin/bash
lutrisver="GE-Proton7-35"
lutris="lutris-$lutrisver-x86_64"
lutrispath="$HOME/.local/share/lutris/runners/wine"
#lutrissha1="86fe8857c4548c9cec8643ded8697495ba426dc7"

preparelutris() {
    lutrisver="$1"
    lutris="lutris-$lutrisver-x86_64"
    if [[ $lutrisver == *"5."* ]]; then
        lutrislink="https://lutris.nyc3.cdn.digitaloceanspaces.com/runners/wine/wine-$lutris"
    elif [[ $lutrisver == *"6."* ]]; then
        lutrislink="https://github.com/lutris/wine/releases/download/lutris-$(echo $lutrisver | cut -c 8-)/wine-$lutris"
    elif [[ $lutrisver == "GE"* ]]; then
        lutrislink="https://github.com/GloriousEggroll/wine-ge-custom/releases/download/$lutrisver/wine-$lutris"
    else
        lutrislink="https://github.com/lutris/wine/releases/download/lutris-wine-$lutrisver/wine-$lutris"
    fi
    lutrispath="$HOME/.local/share/lutris/runners/wine"
    lutrissha1="$2"
    export PATH=$lutrispath/$lutris/bin:$PATH

    cd $HOME/Programs
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

