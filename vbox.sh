#!/bin/bash
echo "run as root (sudo)"
read
pacman -S --noconfirm virtualbox virtualbox-host-dkms virtualbox-guest-iso
pacman -U --noconfirm AUR/virtualbox-ext-oracle/*.xz
usermod -aG vboxusers $SUDO_USER
modprobe vboxdrv
