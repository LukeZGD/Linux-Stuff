#!/bin/bash
lutrisver="7.2-2"
lutris="lutris-$lutrisver-x86_64"
lutrispath="$HOME/.local/share/lutris/runners/wine"
lutrissha1="86fe8857c4548c9cec8643ded8697495ba426dc7"

preparelutris() {
    lutrisver="$1"
    lutris="lutris-$lutrisver-x86_64"
    if [[ $lutrisver == *"5."* ]]; then
        lutrislink="https://lutris.nyc3.cdn.digitaloceanspaces.com/runners/wine/wine-$lutris.tar.xz"
    elif [[ $lutrisver == *"6."* ]]; then
        lutrislink="https://github.com/lutris/wine/releases/download/lutris-$lutrisver/wine-$lutris.tar.xz"
    else
        lutrislink="https://github.com/lutris/wine/releases/download/lutris-wine-$lutrisver/wine-$lutris.tar.xz"
    fi
    lutrispath="$HOME/.local/share/lutris/runners/wine"
    lutrissha1="$2"
    export PATH=$lutrispath/$lutris/bin:$PATH

    cd $HOME/Programs
    if [[ ! -e wine-$lutris.tar.xz || -e wine-$lutris.tar.xz.aria2 ]]; then
        aria2c $lutrislink
    fi

    lutrissha1L=$(shasum wine-$lutris.tar.xz | awk '{print $1}')
    if [[ $lutrissha1L != $lutrissha1 ]]; then
        echo "wine lutris $lutrisver verifying failed"
        echo "expected $lutrissha1, got $lutrissha1L"
        [[ ! -e wine-$lutris.tar.xz.aria2 ]] && rm -f wine-$lutris.tar.xz
        exit 1
    fi

    if [[ ! -d $lutrispath/$lutris ]]; then
        mkdir -p $lutrispath
        7z x wine-$lutris.tar.xz
        tar xvf wine-$lutris.tar -C $lutrispath
        rm -f wine-$lutris.tar
    fi
}

