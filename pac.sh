#!/bin/bash
trap exit INT TERM EXIT

if [[ $1 == autoremove ]]; then
  sudo pacman -Rsn --noconfirm 2>/dev/null
elif [[ $1 == clean ]]; then
  sudo pacman -Sc --noconfirm
elif [[ $1 == update ]]; then
  yay -Syu --noconfirm --answerclean All
elif [[ $1 == install ]]; then
  yay -S --noconfirm --answerclean All ${@:2}
elif [[ $1 == remove ]]; then
  yay -R --noconfirm ${@:2}
elif [[ $1 == purge ]]; then
  yay -Rsn --noconfirm ${@:2}
elif [[ $1 == reflector ]]; then
  sudo reflector --verbose --country 'Singapore' -l 5 --sort rate --save /etc/pacman.d/mirrorlist
else
  echo "Usage: $0 <command>"
  echo "List of commands:
  autoremove
  clean
  update
  install
  remove
  purge
  reflector"
fi
