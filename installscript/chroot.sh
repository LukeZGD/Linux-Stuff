#!/bin/bash

echo "[Log] Setting locale.."
cp /etc/locale.gen /etc/locale.gen.bak
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
rm -rf /etc/locale.gen
mv /etc/locale.gen.bak /etc/locale.gen
echo "[Log] Time stuff"
ln -sf /usr/share/zoneinfo/Hongkong /etc/localtime
hwclock --systohc --utc
echo "[Log] hosts file"
echo "127.0.0.1 localhost" > /etc/hosts
echo "[Log] Running passwd"
passwd
echo "[Input] (y)Grub | (n)systemd-boot"
read grubinstall
if [ $grubinstall == y ]
then
    echo "[Input] Partition? (/dev/sdaX)"
    read part
    echo "[Log] Run grub-install"
    grub-install $part
    echo "[Log] Will now run nano /etc/default/grub. Press [enter]"
    read
    nano /etc/default/grub
    echo "[Log] Run grub-mkconfig"
    grub-mkconfig -o /boot/grub/grub.cfg
fi
if [ $grubinstall == n ]
then
    echo "[Log] run bootctl install"
    bootctl install
    echo "[Input] Please enter root partition (/dev/sdaX)"
    read rootpart
    rootuuid=$(lsblk -no UUID $rootpart)
    echo "[Log] Got UUID of $rootpart: $rootuuid"
    echo "[Input] Please enter swap partition (/dev/sdaX)"
    read swappart
    swapuuid=$(lsblk -no UUID $swappart)
    echo "[Log] Got UUID of $rootpart: $rootuuid"
    echo "[Log] Creating arch.conf entry"
    echo "title Arch Linux
linux /vmlinuz-linux-zen
initrd /intel-ucode.img
initrd /initramfs-linux-zen.img
options root=UUID=$rootuuid rw resume=UUID=$swapuuid loglevel=3 quiet" | sudo tee -a /boot/loader/entries/arch.conf
fi

echo "[Input] Enter username"
read username
echo "[Log] Creating user $username"
useradd -m -g users -G wheel,audio -s /bin/bash $username
echo "[Log] Running passwd $username"
passwd $username
echo "[Input] Create 2nd user account? (y/n)"
read userc2
if [ $userc2 == y ]
then
    echo "[Input] Enter username"
    read username2
    echo "[Log] Creating user $username2"
    useradd -m -g users -G audio -s /bin/bash $username2
    echo "[Log] Running passwd $username2"
    passwd $username2
fi
echo "[Log] Will now run EDITOR=nano visudo. Press [enter]"
read
EDITOR=nano visudo
echo "[Log] Enabling services"
systemctl enable lightdm NetworkManager.service bluetooth.service org.cups.cupsd.service

echo "[Input] Create /etc/X11/xorg.conf.d/30-touchpad.conf? (y/n)"
read touchpad
if [ $touchpad == y ]
then
    echo "Creating /etc/X11/xorg.conf.d/30-touchpad.conf"
    echo 'Section "InputClass"
    Identifier "touchpad"
    Driver "libinput"
    MatchIsTouchpad "on"
    Option "Tapping" "on"
    Option "TappingButtonMap" "lmr"
EndSection' | sudo tee -a /etc/X11/xorg.conf.d/30-touchpad.conf
fi
echo "[Log] Script done"

