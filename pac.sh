#!/bin/bash
trap exit INT TERM EXIT

if [[ $1 == autoremove ]]; then
  sudo pacman -Rsn --noconfirm 2>/dev/null
  [ $? == 1 ] && echo ' there is nothing to do'
elif [[ $1 == clean ]]; then
  sudo pacman -Sc --noconfirm
elif [[ $1 == install ]]; then
  if [ -f $2 ]; then
    install=($2)
    for package in ${@:3}; do
      [ -f $package ] && install+=" $package"
    done
    yay -U --noconfirm ${install[@]}
  else
    yay -S --noconfirm --answerclean All ${@:2}
  fi
elif [[ $1 == reflector ]]; then
  sudo reflector --verbose --country 'Singapore' -l 5 --sort rate --save /etc/pacman.d/mirrorlist
elif [[ $1 == query ]]; then
  yay -Q ${@:2}
elif [[ $1 == remove ]]; then
  yay -R --noconfirm ${@:2}
elif [[ $1 == purge ]]; then
  yay -Rsn --noconfirm ${@:2}
elif [[ $1 == update ]]; then
  yay -Syu --noconfirm --answerclean All
else
  echo "usage:  pac <operation> [...]"
  echo "operations:
    pac {autoremove}
    pac {clean}
    pac {install}
    pac {purge}
    pac {query}
    pac {reflector}
    pac {remove}
    pac {update}"
fi
