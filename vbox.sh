#!/bin/bash
echo "run as root (sudo)"
read
pacman -S --noconfirm virtualbox virtualbox-host-dkms
usermod -aG vboxusers $SUDO_USER
modprobe vboxdrv
