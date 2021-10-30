#!/bin/bash
trap exit INT TERM EXIT

[[ $1 != *c ]] && noconfirm=--noconfirm
if [[ $1 == autoremove* ]]; then
    sudo pacman -Rsn $noconfirm $(pacman -Qdtq) 2>/dev/null
    [[ $? != 0 ]] && echo ' there is nothing to do' || exit $?
elif [[ $1 == clean* ]]; then
    [[ $2 == all ]] && paru -Sc $noconfirm || sudo pacman -Sc $noconfirm
elif [[ $1 == install* || $1 == reinstall* ]]; then
    [[ $1 == install* ]] && needed=--needed
    if [[ -f $2 ]]; then
        install=($2)
        for package in ${@:3}; do
            [[ -f $package ]] && install+=($package)
        done
        paru -U $noconfirm $needed ${install[@]}
    else
        paru -S $noconfirm $needed --sudoloop ${@:2}
    fi
elif [[ $1 == list ]]; then
    if [[ $2 == all ]]; then 
        paru -Q
    elif [[ $2 == aur ]]; then
        paru -Qm
    elif [[ $2 == deps ]]; then
        paru -Qd
    elif [[ $2 == upgrade ]]; then
        paru -Qu
    elif [[ ! -z $2 ]]; then
        paru -Ql $2
    else
        paru -Qe
    fi
elif [[ $1 == query ]]; then
    paru -Q ${@:2}
elif [[ $1 == remove* || $1 == uninstall* ]]; then
    paru -R $noconfirm ${@:2}
elif [[ $1 == purge* ]]; then
    paru -Rsn $noconfirm ${@:2}
elif [[ $1 == update* || $1 == upgrade* ]]; then
    [[ $2 == all ]] || nodevel=--nodevel
    paru -Syu $noconfirm --sudoloop $nodevel
elif [[ $1 == news ]]; then
    paru -Pw
else
    echo "Usage:  pac <operation>[c] [...]"
    echo "Operations:
    pac {autoremove}
    pac {clean} [all]
    pac {install} [package(s)]
    pac {list} [all,aur,deps,upgrade]/[package]
    pac {purge} [package(s)]
    pac {query} [package(s)]
    pac {reinstall} [package(s)]
    pac {remove/uninstall} [package(s)]
    pac {update/upgrade} [all]
    pac {news}"
fi

kernelI=$(pacman -Q linux | awk '{print $2}' | cut -c -7 | tr -d .)
kernelR=$(uname -r | cut -c -7 | tr -d .-)
if [[ $kernelR != $kernelI ]]; then
    echo
    echo "                   *******************************"
    echo "[WARNING] A kernel update has been detected. It is recommended to reboot!"
    echo "                   *******************************"
    echo
fi
