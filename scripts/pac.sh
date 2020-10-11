#!/bin/bash
trap exit INT TERM EXIT

if [[ $1 == autoremove ]] || [[ $1 == autoremovec ]]; then
    [[ $1 != autoremovec ]] && noconfirm=--noconfirm
    sudo pacman -Rsn $noconfirm $(pacman -Qdtq) 2>/dev/null
    [ $? == 1 ] && echo ' there is nothing to do' || exit $?
elif [[ $1 == clean ]] || [[ $1 == cleanc ]]; then
    [[ $1 != cleanc ]] && noconfirm=--noconfirm
    if [[ $2 == all ]]; then 
        yay -Sc $noconfirm
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
        yay -U $noconfirm $needed ${install[@]}
    else
        yay -S $noconfirm $needed --answerclean None --sudoloop ${@:2}
    fi
elif [[ $1 == list ]]; then
    if [[ $2 == all ]]; then 
        yay -Q
    elif [[ $2 == upgrade ]]; then
        yay -Qu
    else
        yay -Qe
    fi
elif [[ $1 == query ]]; then
    yay -Q ${@:2}
elif [[ $1 == remove ]] || [[ $1 == removec ]]; then
    [[ $1 != removec ]] && noconfirm=--noconfirm
    yay -R $noconfirm ${@:2}
elif [[ $1 == reflector ]]; then
    sudo systemctl start reflector
    systemctl status reflector
elif [[ $1 == purge ]] || [[ $1 == purgec ]]; then
    [[ $1 != purgec ]] && noconfirm=--noconfirm
    yay -Rsn $noconfirm ${@:2}
elif [[ $1 == update ]]; then
    yay -Sy
elif [[ $1 == upgrade ]] || [[ $1 == upgradec ]]; then
    [[ $1 != upgradec ]] && noconfirm=--noconfirm
    yay -Syu $noconfirm --answerclean None --sudoloop
else
    echo "Usage:  pac <operation>(c) [...]"
    echo "Operations:
    pac {autoremove}
    pac {clean} [all]
    pac {install} [package(s)]
    pac {list} [all,upgrade]
    pac {purge} [package(s)]
    pac {query} [package(s)]
    pac {reinstall} [package(s)]
    pac {remove} [package(s)]
    pac {reflector}
    pac {update}
    pac {upgrade}"
fi
