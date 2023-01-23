#!/bin/bash

pacmanpkgs=(
amd-ucode
base-devel
dialog
fish
git
kernel-modules-hook
linux-firmware
nano
pacman-contrib
reflector
terminus-font
usbutils
vim
wget
zram-generator

alsa-utils
pavucontrol-qt
pipewire
pipewire-alsa
pipewire-pulse

libva-mesa-driver
vulkan-icd-loader
vulkan-radeon
xorg-server
xorg-xinit
xorg-xrandr

bluez
bluez-plugins
bluez-utils
iwd
networkmanager
networkmanager-openvpn
network-manager-applet
openvpn
systemd-resolvconf

btrfs-progs
compsize
exfatprogs
f2fs-tools
ntfs-3g
rsync

p7zip
unzip
unrar
zip

cups-pdf
foomatic-db-gutenprint-ppds
gutenprint
hplip

plasma
ark
dolphin
k3b
kate
kdeconnect
kdegraphics-thumbnailers
kdesdk-kio
kdesdk-thumbnailers
kfind
kimageformats
kio
kio-extras
kio-fuse
kmix
konsole
ksysguard
kwalletmanager
qt5-imageformats
spectacle
taglib

breeze-gtk
ccache
gnome-disk-utility
gparted
kdialog
nano-syntax-highlighting
neofetch
plasma-browser-integration
print-manager
simple-scan
system-config-printer
ttf-dejavu

audacious
audacity
ffmpeg
ffmpegthumbs
ffmpegthumbnailer
fluidsynth
gimp
kate
kdenlive
kolourpaint
mpv
obs-studio
okteta

freerdp
krdc
libvncserver

aria2
bat
cdrdao
cdrtools
chromium
corectrl
dosbox
dvd+rw-tools
firefox
fwupd
geoip
gnome-calculator
gnome-keyring
htop
jq
jre-openjdk
jsoncpp
libreoffice-fresh
linssid
love
maxcso
okular
openssh
noto-fonts-cjk
noto-fonts-emoji
piper
python-pip
radeontop
retext
samba
sshfs
tealdeer
transmission-qt
v4l2loopback-dkms
xdelta3
xdg-desktop-portal
xdg-desktop-portal-kde
zenity
)

systemdinstall() {
    pacman -S --noconfirm --needed efibootmgr
    echo "[Log] run bootctl install"
    bootctl install
    lsblk
    read -p "[Input] Please enter encrypted partition (/dev/sdaX) " rootpart
    rootuuid=$(blkid -o value -s UUID $rootpart)
    echo "[Log] Got UUID of root $rootpart: $rootuuid"
    echo "[Log] Creating arch.conf entry"
    echo "title Arch Linux
    linux /vmlinuz-$kernel
    initrd /amd-ucode.img
    initrd /initramfs-$kernel.img
    options cryptdevice=UUID=$rootuuid:lvm:allow-discards root=/dev/mapper/vg0-root rw loglevel=3 splash nowatchdog rd.udev.log_priority=3" > /boot/loader/entries/arch.conf
    echo "timeout 0
    default arch
    editor 0" > /boot/loader/loader.conf
}

# ----------------

echo "[Log] pacman.conf"
sed -i "s/#Color/Color/" /etc/pacman.conf
sed -i "s|#ParallelDownloads = 5|ParallelDownloads = 5|g" /etc/pacman.conf
sed -i "s|#IgnorePkg   =|IgnorePkg    = python2|g" /etc/pacman.conf
echo "[Input] Select kernel:"
select opt in "linux" "linux-lts" "linux-zen"; do
case $opt in
    "linux" ) kernel=linux; break;;
    "linux-lts" ) kernel=linux-lts; break;;
    "linux-zen" ) kernel=linux-zen; break;;
esac
done
echo "[Log] archlinux-keyring"
pacman -S --noconfirm archlinux-keyring
echo "[Log] Installing packages"
pacman -S --noconfirm $kernel $kernel-headers
pacman -S --noconfirm --needed "${pacmanpkgs[@]}"
if [[ $? != 0 ]]; then
    echo "pacman seems to not have completed successfully. please edit chroot.sh. press enter"
    read -s
    nano chroot.sh
    ./chroot.sh
    exit
fi
echo "[Log] Setting locale"
echo -e "en_CA.UTF-8 UTF-8\nen_US.UTF-8 UTF-8\nja_JP.UTF-8 UTF-8" > /etc/locale.gen
echo "LANG=en_CA.UTF-8" > /etc/locale.conf
locale-gen
echo "[Log] Time stuff"
ln -sf /usr/share/zoneinfo/Asia/Manila /etc/localtime
hwclock --systohc
timedatectl set-ntp true
echo "[Log] Running passwd"
passwd
echo "[Log] Setup systemd-boot"
systemdinstall
echo "[Log] Edit mkinitcpio and dkms"
printf "MODULES=()\nBINARIES=()\nFILES=()\nHOOKS=(base udev autodetect modconf kms keyboard keymap consolefont block encrypt lvm2 filesystems fsck)\n" > /etc/mkinitcpio.conf
echo "sign_file='/usr/lib/modules/\${kernelver}/build/scripts/sign-file'" > /etc/dkms/framework.conf.d/custom.conf
pacman -S --noconfirm $kernel $kernel-headers

read -p "[Input] Enter hostname: " hostname
echo "[Log] Creating /etc/hostname"
echo $hostname > /etc/hostname
echo "[Log] hosts file"
echo -e "127.0.0.1 localhost
::1       localhost
127.0.1.1 $hostname" >> /etc/hosts
read -p "[Input] Enter username: " username
echo "[Log] Creating user $username"
useradd -m -g users -G audio,optical,storage,wheel -s /bin/bash $username
echo "[Log] Running passwd $username"
passwd $username
echo "[Log] Running visudo"
echo "%wheel ALL=(ALL) ALL" | EDITOR="tee -a" visudo

echo "[Log] do stuff services"
systemctl disable NetworkManager-wait-online
systemctl mask NetworkManager-wait-online
sed -i "s|--sort age|--sort rate|g" /etc/xdg/reflector/reflector.conf

echo "[Log] Enabling services"
systemctl enable NetworkManager bluetooth cups fstrim.timer linux-modules-cleanup reflector.timer sddm systemd-resolved systemd-timesyncd

if [[ -d /mnt/Data ]]; then
    echo "[Log] Running \"chown -R 1000:1000 /mnt/Data\", please wait"
    chown -R 1000:1000 /mnt/Data
fi
rm -rf /media
ln -sf /run/media /media

echo "[Log] Power management and lock"
echo 'HandlePowerKey=suspend
HandleLidSwitch=suspend
HandleLidSwitchExternalPower=suspend
HandleLidSwitchDocked=suspend
IdleAction=suspend
IdleActionSec=15min' | tee -a /etc/systemd/logind.conf

echo "[Log] Terminus font"
echo 'FONT=ter-p32n
FONT_MAP=8859-2' | tee /etc/vconsole.conf

read -p "[Input] Create /etc/X11/xorg.conf.d/30-touchpad.conf? (for laptop touchpads) (Y/n) " touchpad
if [[ $touchpad != 'n' && $touchpad != 'N' ]]; then
    echo "[Log] Creating /etc/X11/xorg.conf.d/30-touchpad.conf"
    echo 'Section "InputClass"
        Identifier "Touchpad"
        MatchIsTouchpad "on"
        MatchDriver "libinput"
        Option "AccelProfile" "adaptive"
        Option "AccelSpeed" "0.2"
        Option "Tapping" "on"
        Option "TappingButtonMap" "lrm"
        Option "NaturalScrolling" "true"
        Option "DisableWhileTyping" "false"
EndSection' > /etc/X11/xorg.conf.d/30-touchpad.conf
fi

echo 'Section "InputClass"
        Identifier "Mouse"
        MatchIsPointer "on"
        MatchDriver "libinput"
        Option "AccelProfile" "flat"
        Option "AccelSpeed" "0.8"
        Option "MiddleEmulation" "on"
EndSection' > /etc/X11/xorg.conf.d/00-mouse.conf

echo 'Section "InputClass"
   Identifier   "ds4-touchpad"
   Driver       "libinput"
   MatchProduct "Wireless Controller Touchpad"
   Option       "Ignore" "True"
EndSection' > /etc/X11/xorg.conf.d/30ds4.conf

echo '[zram0]
zram-fraction = 1.0
max-zram-size = 8192' > /etc/systemd/zram-generator.conf

echo 'blacklist pcspkr' > /etc/modprobe.d/nobeep.conf
echo 'ohci_hcd' > /etc/modules-load.d/ohci_hcd.conf
echo "v4l2loopback" > /etc/modules-load.d/v4l2loopback.conf

sed -i "s|#DefaultTimeoutStopSec=90s|DefaultTimeoutStopSec=15s|" /etc/systemd/system.conf

mkdir /var/cache/pacman/aur
chown -R 1000:1000 /var/cache/pacman/aur
sed -i "s|#PKGDEST=/home/packages|PKGDEST=/var/cache/pacman/aur|" /etc/makepkg.conf

echo "[Log] nanorc"
echo 'include "/usr/share/nano/*.nanorc"
include "/usr/share/nano-syntax-highlighting/*.nanorc"' | tee /etc/nanorc

echo "[Log] makepkg.conf"
sed -i "s|BUILDENV=(!distcc color !ccache check !sign)|BUILDENV=(!distcc color ccache check !sign)|g" /etc/makepkg.conf
sed -i "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j"$(nproc)"\"/" /etc/makepkg.conf
sed -i "s|          'ftp::/usr/bin/curl -gqfC - --ftp-pasv --retry 3 --retry-delay 3 -o %o %u'|          'ftp::/usr/bin/aria2c -UWget -s4 %u -o %o'|g" /etc/makepkg.conf
sed -i "s|          'http::/usr/bin/curl -gqb \"\" -fLC - --retry 3 --retry-delay 3 -o %o %u'|          'http::/usr/bin/aria2c -UWget -s4 %u -o %o'|g" /etc/makepkg.conf
sed -i "s|          'https::/usr/bin/curl -gqb \"\" -fLC - --retry 3 --retry-delay 3 -o %o %u'|          'https::/usr/bin/aria2c -UWget -s4 %u -o %o'|g" /etc/makepkg.conf

echo 'ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
ACTION=="add|change", KERNEL=="sd[a-z]|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"' | tee /etc/udev/rules.d/60-ioschedulers.rules
printf "kernel.panic=3\nkernel.sysrq=1\nvm.swappiness=1\n" | tee /etc/sysctl.d/99-sysctl.conf
sed -i "s|ExecStart=/usr/lib/bluetooth/bluetoothd|ExecStart=/usr/lib/bluetooth/bluetoothd --noplugin=avrcp|g" /etc/systemd/system/bluetooth.target.wants/bluetooth.service

echo '[device]
wifi.backend=iwd' > /etc/NetworkManager/conf.d/wifi_backend.conf

echo "[Log] chroot script done"
