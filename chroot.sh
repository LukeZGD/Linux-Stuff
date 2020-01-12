#!/bin/bash

pacman=(
base-devel
fish
intel-ucode
linux-firmware
linux-zen
linux-zen-headers
nano
usbutils

dialog
git
neofetch
rsync
pacman-contrib
wget

alsa-utils
pavucontrol
pulseaudio
pulseaudio-alsa
pulseaudio-bluetooth

xorg-server
xorg-xinit
xorg-xrandr
lightdm
lightdm-gtk-greeter
lightdm-gtk-greeter-settings

xfce4
xfce4-goodies

networkmanager
network-manager-applet

bluez
bluez-plugins
bluez-utils
blueman

gnome-disk-utility
gparted
gvfs
gvfs-afc
gvfs-gphoto2
ntfs-3g

file-roller
p7zip
zip
unzip
unrar
)

#qt5-styleplugins
pacman2=(
papirus-icon-theme

cups-pdf
foomatic-db-gutenprint-ppds
gutenprint
hplip
simple-scan
system-config-printer

audacity
ffmpeg
ffmpegthumbnailer
handbrake
kdenlive
kolourpaint
lame
mcomix
notepadqq
obs-studio
okteta
openshot
pinta
vlc

gnome-keyring
seahorse

catfish
mlocate

filezilla
galculator
htop
ifuse
jre8-openjdk
libreoffice
openssh
noto-fonts-cjk
noto-fonts-emoji
qbittorrent
samba
testdisk
uget
xfburn
)

function grubinstall {
    pacman -S --noconfirm grub
    lsblk
    echo "[Input] Disk? (/dev/sdX)"
    read part
    echo "[Input] Please enter encrypted partition (/dev/sdaX)"
    read rootpart
    rootuuid=$(blkid -o value -s UUID $rootpart)
    echo "[Log] Got UUID of $rootpart: $rootuuid"
    echo "[Log] Run grub-install"
    grub-install $part --target=$grubtarget
	echo "[Log] Edit /etc/default/grub"
    sed -i "s/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/" /etc/default/grub
    sed -i "s/GRUB_CMDLINE_LINUX=\"\"/GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=$rootuuid:lvm:allow-discards\"/" /etc/default/grub
    echo "[Log] Run grub-mkconfig"
	grub-mkconfig -o /boot/grub/grub.cfg
}

function systemdinstall {
    echo "[Log] run bootctl install"
    bootctl install
    lsblk
    echo "[Input] Please enter encrypted partition (/dev/sdaX)"
    read rootpart
    rootuuid=$(blkid -o value -s UUID $rootpart)
    echo "[Log] Got UUID of $rootpart: $rootuuid"
    echo "[Log] Creating arch.conf entry"
    echo "title Arch Linux
linux /vmlinuz-linux-zen
initrd /intel-ucode.img
initrd /initramfs-linux-zen.img
options cryptdevice=UUID=$rootuuid:lvm:allow-discards resume=/dev/mapper/vg0-swap root=/dev/mapper/vg0-root rw quiet" > /boot/loader/entries/arch.conf
	echo "timeout 0
default arch
editor 0" > /boot/loader/loader.conf
}

echo "[Log] Installing packages listed in 'pacman'"
pacman -S --noconfirm ${pacman[*]}
echo "[Log] Installing packages listed in 'pacman2'"
pacman -S --noconfirm ${pacman2[*]}
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

if [ $(which efibootmgr) ]
then
    grubtarget=i386-efi
    echo "[Log] Installing grub"
    grubinstall
else
    grubtarget=i386-pc
    echo "[Input] Select boot manager (grub for legacy, systemd-boot for UEFI)"
    select opt in "grub" "systemd-boot"; do
        case $opt in
            "grub" ) grubinstall; break;;
            "systemd-boot" ) systemdinstall; break;;
        esac
    done
fi

echo "[Log] Edit mkinitcpio.conf"
sed -i "s/HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/HOOKS=(base udev autodetect modconf block keyboard encrypt lvm2 resume filesystems fsck)/" /etc/mkinitcpio.conf
sed -i "s/MODULES=()/MODULES=(ext4)/" /etc/mkinitcpio.conf
echo "[Log] Run mkinitcpio"
mkinitcpio -p linux-zen

echo "[Input] Enter hostname"
read hostname
echo "[Log] Creating /etc/hostname"
echo $hostname > /etc/hostname
echo "[Input] Enter username"
read username
echo "[Log] Creating user $username"
useradd -m -g users -G wheel,audio -s /usr/bin/fish $username
echo "[Log] Running passwd $username"
passwd $username
echo "[Input] Create 2nd user account? (with no wheel/sudo) (y/n)"
read userc2
if [ $userc2 == y ]
then
    echo "[Input] Enter username"
    read username2
    echo "[Log] Creating user $username2"
    useradd -m -g users -G audio -s /usr/bin/fish $username2
    echo "[Log] Running passwd $username2"
    passwd $username2
fi
echo "[Log] Running visudo"
echo "%wheel ALL=(ALL) ALL" | EDITOR="tee -a" visudo
echo "[Log] Enabling services"
systemctl enable lightdm NetworkManager bluetooth
systemctl enable org.cups.cupsd

echo "[Input] Create /etc/X11/xorg.conf.d/30-touchpad.conf? (for laptop touchpads) (y/n)"
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

sed -i "s/#session-cleanup-script=/session-cleanup-script=\/usr\/bin\/unmountonlogout/" /etc/lightdm/lightdm.conf
#echo "QT_QPA_PLATFORMTHEME=gtk2" >> /etc/environment
echo "Removing chroot.sh"
rm /chroot.sh