#!/bin/bash
trap exit INT TERM EXIT

if [[ $1 == autoremove ]] || [[ $1 == autoremovec ]]; then
    [[ $1 != autoremovec ]] && noconfirm=--noconfirm
    sudo pacman -Rsn $noconfirm $(pacman -Qdtq) 2>/dev/null
    [ $? == 1 ] && echo ' there is nothing to do' || exit $?
elif [[ $1 == clean ]] || [[ $1 == cleanc ]]; then
    [[ $1 != cleanc ]] && noconfirm=--noconfirm
    if [[ $2 == all ]]; then 
        paru -Sc $noconfirm
    else
        sudo pacman -Sc $noconfirm
    fi
elif [[ $1 == install ]] || [[ $1 == reinstall ]] ||
     [[ $1 == installc ]] || [[ $1 == reinstallc ]]; then
    [[ $1 != installc ]] && [[ $1 != reinstallc ]] && noconfirm=--noconfirm
    [[ $1 == install ]] && needed=--needed
    if [ -f $2 ]; then
        install=($2)
        for package in ${@:3}; do
        [ -f $package ] && install+=($package)
        done
        paru -U $noconfirm $needed ${install[@]}
    else
        paru -S $noconfirm $needed --sudoloop ${@:2}
    fi
    kernelI=$(pacman -Q linux-zen | awk '{print $2}' | cut -c -6 | tr -d .)
    kernelR=$(uname -r | cut -c -6 | tr -d . | tr -d -)
    if [[ $kernelR != $kernelI ]]; then
        echo
        echo "                   *******************************"
        echo "[WARNING] A kernel update has been detected. It is recommended to reboot!"
        echo "                   *******************************"
        echo
    fi
elif [[ $1 == list ]]; then
    if [[ $2 == all ]]; then 
        paru -Q
    elif [[ $2 == upgrade ]]; then
        paru -Qu
    elif [[ ! -z $2 ]]; then
        paru -Ql $2
    else
        paru -Qe
    fi
elif [[ $1 == query ]]; then
    paru -Q ${@:2}
elif [[ $1 == remove ]] || [[ $1 == removec ]] ||
     [[ $1 == uninstall ]] || [[ $1 == uninstallc ]]; then
    [[ $1 != removec ]] && [[ $1 != uninstallc ]] && noconfirm=--noconfirm
    paru -R $noconfirm ${@:2}
elif [[ $1 == reflector ]]; then
    sudo systemctl start reflector
    systemctl status reflector
elif [[ $1 == purge ]] || [[ $1 == purgec ]]; then
    [[ $1 != purgec ]] && noconfirm=--noconfirm
    paru -Rsn $noconfirm ${@:2}
elif [[ $1 == update ]] || [[ $1 == updatec ]] ||
     [[ $1 == upgrade ]] || [[ $1 == upgradec ]]; then
    [[ $1 != updatec ]] && [[ $1 != upgradec ]] && noconfirm=--noconfirm
    paru -Syu $noconfirm --sudoloop
else
    echo "Usage:  pac <operation>(c) [...]"
    echo "Operations:
    pac {autoremove}
    pac {clean} [all]
    pac {install} [package(s)]
    pac {list} [all,upgrade]/[package]
    pac {purge} [package(s)]
    pac {query} [package(s)]
    pac {reinstall} [package(s)]
    pac {remove/uninstall} [package(s)]
    pac {reflector}
    pac {update/upgrade}"
fi
