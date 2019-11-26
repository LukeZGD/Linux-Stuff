#!/bin/bash

function grubinstall {
    lsblk
    echo "[Input] Disk? (/dev/sdX)"
    read part
    echo "[Log] Run grub-install"
    grub-install $part
    sed -i "s/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/" /etc/default/grub
    grub-mkconfig -o /boot/grub/grub.cfg
}

function systemdinstall {
    echo "[Log] run bootctl install"
    bootctl install
    lsblk
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
options root=UUID=$rootuuid rw resume=UUID=$swapuuid loglevel=3 quiet" > /boot/loader/entries/arch.conf
fi
}

echo "[Log] Installing packages listed in 'pacman'"
pacman -S --noconfirm - < /pacman
echo "[Log] Installing packages listed in 'pacman2'"
pacman -S --noconfirm - < /pacman2
echo "[Log] Setting locale.."
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "[Log] Time stuff"
ln -sf /usr/share/zoneinfo/Hongkong /etc/localtime
hwclock -w --localtime
echo "[Log] hosts file"
echo "127.0.0.1 localhost" >> /etc/hosts
echo "[Log] Running passwd"
passwd
echo "[Input]"
select opt in "grub" "systemd-boot"; do
    case $opt in
        "grub" ) grubinstall; break;;
        "systemd-boot" ) systemdinstall; break;;
    esac
done

echo "[Input] Enter hostname"
read hostname
echo "[Log] Creating /etc/hostname"
echo $hostname > /etc/hostname
echo "[Input] Enter username"
read username
echo "[Log] Creating user $username"
useradd -m -g users -G wheel,audio -s /bin/bash $username
echo "[Log] Running passwd $username"
passwd $username
echo "[Input] Create 2nd user account? (with no wheel/sudo) (y/n)"
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
echo "[Log] Running visudo"
echo "%wheel ALL=(ALL) ALL" | sudo EDITOR="tee -a" visudo
echo "[Log] Enabling services"
systemctl enable lightdm NetworkManager bluetooth
systemctl enable org.cups.cupsd

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
EndSection' > /etc/X11/xorg.conf.d/30-touchpad.conf
fi
echo "Removing install stuff from root"
rm -rf /pacman
rm -rf /pacman2
rm -rf /chroot.sh

