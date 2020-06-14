#!/bin/bash

pacmanpkgs=(
base-devel
ccache
dialog
fish
git
intel-ucode
linux-firmware
linux-lts
linux-lts-headers
nano
nano-syntax-highlighting
neofetch
pacman-contrib
reflector
rsync
usbutils
wget

alsa-utils
pavucontrol
pulseaudio
pulseaudio-alsa
pulseaudio-bluetooth

xorg-server
xorg-xinit
xorg-xrandr

bluez
bluez-plugins
bluez-utils
networkmanager
network-manager-applet

exfat-utils
gnome-disk-utility
gparted
gvfs
gvfs-afc
gvfs-gphoto2
ntfs-3g

p7zip
zip
unzip
unrar

cups-pdf
foomatic-db-gutenprint-ppds
gutenprint
hplip
simple-scan
system-config-printer

audacious
audacity
ffmpeg
ffmpegthumbs
ffmpegthumbnailer
fluidsynth
gimp
handbrake
kate
kdenlive
lame
mpv
obs-studio
okteta
viewnior

firefox
gnome-keyring
gsmartcontrol
htop
jre8-openjdk
krdc
libressl
love
openssh
noto-fonts-cjk
noto-fonts-emoji
papirus-icon-theme
qbittorrent
freerdp
samba
seahorse
testdisk
)

pacmanxfce4=(
lightdm
lightdm-gtk-greeter
lightdm-gtk-greeter-settings
blueman
catfish
engrampa
xfce4
xfce4-goodies
galculator
light-locker
xfburn
)

pacmankde=(
plasma
ark
k3b
kate
kcalc
kdialog
kmix
konsole
kwalletmanager
pcmanfm-qt
spectacle
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
  grub-install $part --target=i386-pc
  echo "[Log] Edit /etc/default/grub"
  sed -i "s/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/" /etc/default/grub
  sed -i "s|GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet\"|GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 resume=/dev/mapper/vg0-swap\"|g" /etc/default/grub
  sed -i "s/GRUB_CMDLINE_LINUX=\"\"/GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=$rootuuid:lvm:allow-discards\"/" /etc/default/grub
  echo "[Log] Run grub-mkconfig"
  grub-mkconfig -o /boot/grub/grub.cfg
}

function grubinstallia32 {
  pacman -S --noconfirm grub efibootmgr
  lsblk
  echo "[Input] Disk? (/dev/sdX)"
  read part
  echo "[Input] Please enter swap partition (/dev/sdaX)"
  read swappart
  swapuuid=$(blkid -o value -s UUID $swappart)
  echo "[Log] Got UUID of $swappart: $swapuuid"
  echo "[Log] Run grub-install"
  grub-install $part --target=i386-efi
  sed -i "s|GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet\"|GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 resume=UUID=$swapuuid\"|g" /etc/default/grub
  sed -i "s/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/" /etc/default/grub
  grub-mkconfig -o /boot/grub/grub.cfg
}

function systemdinstall {
  pacman -S --noconfirm efibootmgr
  echo "[Log] run bootctl install"
  bootctl install
  lsblk
  echo "[Input] Please enter encrypted partition (/dev/sdaX)"
  read rootpart
  rootuuid=$(blkid -o value -s UUID $rootpart)
  echo "[Log] Got UUID of $rootpart: $rootuuid"
  echo "[Log] Creating arch.conf entry"
  echo "title Arch Linux
linux /vmlinuz-linux-lts
initrd /intel-ucode.img
initrd /initramfs-linux-lts.img
options cryptdevice=UUID=$rootuuid:lvm:allow-discards resume=/dev/mapper/vg0-swap root=/dev/mapper/vg0-root rw loglevel=3" > /boot/loader/entries/arch.conf
	echo "timeout 0
default arch
editor 0" > /boot/loader/loader.conf
}

# ----------------

echo "[Log] Installing packages"
pacman -S --noconfirm ${pacmanpkgs[*]}
#echo "[Input] (Y) KDE | (n) XFCE"
#read desktopenv
if [[ $desktopenv == n ]] || [[ $desktopenv == N ]]; then
  pacman -S --noconfirm ${pacmanxfce4[*]}
else
  pacman -S --noconfirm ${pacmankde[*]}
fi
echo "[Log] Setting locale"
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
locale-gen
echo "[Log] Time stuff"
ln -sf /usr/share/zoneinfo/Hongkong /etc/localtime
hwclock --systohc
echo "[Log] hosts file"
echo "127.0.0.1 localhost" >> /etc/hosts
echo "[Log] Running passwd"
passwd

if [ -f /ia32 ]; then
  echo "[Log] Installing grub"
  grubinstallia32
  rm /ia32
else
  if [ -f /fdisk ]; then
    echo "[Log] Setup grub"
    grubinstall
  else
    echo "[Log] Setup systemd-boot"
    systemdinstall
  fi
fi

echo "[Log] Edit mkinitcpio.conf"
sed -i "s/HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/HOOKS=(base udev autodetect modconf block keyboard encrypt lvm2 resume filesystems fsck)/" /etc/mkinitcpio.conf
sed -i "s/MODULES=()/MODULES=(ext4)/" /etc/mkinitcpio.conf
echo "[Log] Run mkinitcpio"
mkinitcpio -p linux-lts

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
echo "[Log] Running visudo"
echo "%wheel ALL=(ALL) ALL" | EDITOR="tee -a" visudo
echo "[Log] Enabling services"
systemctl enable NetworkManager bluetooth org.cups.cupsd fstrim.timer
if [[ $desktopenv == n ]] || [[ $desktopenv == N ]]; then
  systemctl enable lightdm
else
  systemctl enable sddm
fi


echo "[Input] Create /etc/X11/xorg.conf.d/30-touchpad.conf? (for laptop touchpads) (y/N)"
read touchpad
if [ $touchpad == y ] || [ $touchpad == Y ]; then
  echo "[Log] Creating /etc/X11/xorg.conf.d/30-touchpad.conf"
  echo 'Section "InputClass"
  Identifier "touchpad"
  Driver "libinput"
  MatchIsTouchpad "on"
  Option "Tapping" "on"
  Option "TappingButtonMap" "lmr"
EndSection' > /etc/X11/xorg.conf.d/30-touchpad.conf
fi

echo "[Log] unmountonlogout"
cat > /usr/bin/unmountonlogout << 'EOF'
#!/bin/bash
for device in /sys/block/*
do
  if udevadm info --query=property --path=$device | grep -q ^ID_BUS=usb
  then
    echo Found $device to unmount
    DEVTO=`echo $device|awk -F"/" 'NF>1{print $NF}'`
    echo `df -h|grep "$(ls /dev/$DEVTO*)"|awk '{print $1}'` is the exact device
    UM=`df -h|grep "$(ls /dev/$DEVTO*)"|awk '{print $1}'`
    if sudo umount $UM
      then echo Done umounting
    fi
  fi
done
EOF
chmod +x /usr/bin/unmountonlogout
#sed -i "s/#session-cleanup-script=/session-cleanup-script=\/usr\/bin\/unmountonlogout/" /etc/lightdm/lightdm.conf

echo "[Log] Power management and lock"
echo 'HandlePowerKey=suspend
HandleLidSwitch=suspend
HandleLidSwitchExternalPower=suspend
IdleAction=suspend
IdleActionSec=30min' | tee -a /etc/systemd/logind.conf

echo "[Log] LightDM GTK config"
#cat > /etc/lightdm/lightdm-gtk-greeter.conf << 'EOF'
#[greeter]
#theme-name = Adwaita-dark
#icon-theme-name = Papirus-Dark
#font-name = Cantarell 20
#background = /usr/share/backgrounds/adapta/tealized.jpg
#user-background = false
#clock-format = %a %d %b, %I:%M %p
#EOF

echo "[Log] nanorc"
echo 'include "/usr/share/nano/*.nanorc"
include "/usr/share/nano-syntax-highlighting/*.nanorc"' | tee /etc/nanorc

echo "[Log] pacman.conf"
sed -i "s/#Color/Color/" /etc/pacman.conf
sed -i "s/#TotalDownload/TotalDownload/" /etc/pacman.conf

echo "[Log] makepkg.conf"
sed -i "s|COMPRESSZST=(zstd -c -z -q -)|COMPRESSZST=(zstd -c -T0 -18 -)|g" /etc/makepkg.conf
sed -i "s/PKGEXT='.pkg.tar.xz'/PKGEXT='.pkg.tar.zst'/" /etc/makepkg.conf
sed -i "s|BUILDENV=(!distcc color !ccache check !sign)|BUILDENV=(!distcc color ccache check !sign)|g" /etc/makepkg.conf
sed -i "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j"$(nproc)"\"/" /etc/makepkg.conf

echo "[Log] /etc/environment"
echo "mesa_glthread=true" | tee /etc/environment

echo "[Log] rc-local"
echo '[Unit]
Description=/etc/rc.local compatibility

[Service]
Type=oneshot
ExecStart=/etc/rc.local
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target' | tee /usr/lib/systemd/system/rc-local.service
echo '#!/bin/bash
echo 0,0,345,345 |  tee /sys/module/veikk/parameters/bounds_map
exit 0' | tee /etc/rc.local
chmod +x /etc/rc.local
systemctl enable rc-local

echo "[Log] modprobe ohci_hcd"
modprobe ohci_hcd

echo "[Log] chroot script done"
