#!/bin/bash
trap exit INT TERM EXIT

if [[ $1 == autoremove ]]; then
    sudo pacman -Rsn --noconfirm 2>/dev/null
    [ $? == 1 ] && echo ' there is nothing to do'
elif [[ $1 == clean ]]; then
    if [[ $2 == all ]]; then 
        yay -Sc --noconfirm
    else
        sudo pacman -Sc --noconfirm
    fi
elif [[ $1 == install ]]; then
    if [ -f $2 ]; then
        install=($2)
        for package in ${@:3}; do
        [ -f $package ] && install+=($package)
        done
        yay -U --noconfirm --needed ${install[@]}
    else
        yay -S --noconfirm --needed --answerclean None --sudoloop ${@:2}
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
elif [[ $1 == remove ]]; then
    yay -R --noconfirm ${@:2}
elif [[ $1 == purge ]]; then
    yay -Rsn --noconfirm ${@:2}
elif [[ $1 == update ]]; then
    yay -Sy
    yay -Qu
elif [[ $1 == upgrade ]]; then
    yay -Syu --noconfirm --answerclean None --sudoloop
else
    echo "Usage:  pac <operation> [...]"
    echo "Operations:
    pac {autoremove}
    pac {clean} [all]
    pac {install} [package(s)]
    pac {list} [all,upgrade]
    pac {purge} [package(s)]
    pac {query} [package(s)]
    pac {remove} [package(s)]
    pac {update} [package(s)]
    pac {upgrade}"
fi
