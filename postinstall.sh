#!/bin/bash

packages=(
checkra1n-cli
gconf
libirecovery-git
libsndio-61-compat
ncurses5-compat-libs
python2-twodict-git

adapta-backgrounds
adwaita-qt
chromium-vaapi-bin
chromium-widevine
etcher-bin
gallery-dl
github-desktop-bin
qdirstat
woeusb
wps-office
yay-bin
youtube-dl-gui-git
)

emulators=(
dolphin-emu
pcsx2
libretro-beetle-psx-hw
libretro-bsnes
libretro-citra
libretro-core-info
libretro-desmume
libretro-gambatte
libretro-melonds
libretro-mgba
libretro-mupen64plus-next
libretro-nestopia
libretro-overlays
libretro-ppsspp
libretro-snes9x
retroarch
retroarch-assets-ozone
retroarch-assets-xmb
)

osu='
#!/bin/sh
export WINEPREFIX="$HOME/.wine_osu"
cd $HOME/osu # Or wherever you installed osu! in
wine osu!.exe "$@"
'

osukill='
#!/bin/sh
export WINEPREFIX="$HOME/.wine_osu"
wineserver -k
'

function postinstall {
  sudo rsync -va --update --delete-after /run/media/$USER/LukeHDD2/Backups/yay/ /home/$USER/.cache/yay/
  for package in "${packages[@]}"
  do
    sudo pacman -U --noconfirm $HOME/.cache/yay/$package/${package}*.xz
  done
  sudo pacman -U $HOME/.cache/yay/libimobiledevice-git/libimobiledevice-git*.xz
  sudo pacman -U --noconfirm $HOME/.cache/yay/idevicerestore-git/idevicerestore-git*.xz
  postinstallcomm
}

function postinstallyay {
  git clone https://aur.archlinux.org/yay-bin.git
  cd yay-bin
  makepkg -si --noconfirm
  rm -rf yay-bin
  for package in "${packages[@]}"
  do
    yay --noconfirm $package
  done
  yay libimobiledevice-git
  yay --noconfirm idevicerestore-git
  postinstallcomm
}

function postinstallcomm {
  [ -e $HOME/Documents/packages/ ] && sudo pacman -U $HOME/Documents/packages/* #for veikk drivers and fonts
  gsettings set org.nemo.desktop font 'Cantarell Regular 10'
  gsettings set org.nemo.preferences size-prefixes 'base-2'
  xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/logind-handle-power-key -n -t bool -s true
  xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/logind-handle-lid-switch -n -t bool -s true
  autocreate "nemo-desktop" "env GTK_THEME=Adwaita nemo-desktop"
  autocreate "light-locker"
  autocreate "xfce4-clipman"
  autocreate "nitrogen" "nitrogen --set-auto $HOME/Pictures/background.png"
}

function autocreate {
  if [ -z "$2" ]; then
    a=$1
  else
    a=$2
  fi
  echo "[Desktop Entry]
Encoding=UTF-8
Version=0.9.4
Type=Application
Name=$1
Exec=$a
OnlyShowIn=XFCE;
RunHook=0
StartupNotify=false
Terminal=false
Hidden=false" > $HOME/.config/autostart/$1.desktop
}

function vbox {
  sudo pacman -S --noconfirm virtualbox virtualbox-host-dkms virtualbox-guest-iso
  sudo pacman -U --noconfirm $HOME/.cache/yay/virtualbox-ext-oracle/*.xz
  sudo usermod -aG vboxusers $USER
  sudo modprobe vboxdrv
}

function laptop {
  sudo pacman -S --noconfirm bbswitch-dkms nvidia-lts nvidia-settings tlp
  sudo pacman -U --noconfirm $HOME/.cache/yay/optimus-manager/*.xz $HOME/.cache/yay/optimus-manager-qt/*.xz
  sudo systemctl enable tlp
}

function 390xx {
  sudo pacman -S --noconfirm nvidia-390xx-lts nvidia-390xx-settings
}

function emulatorsinstall {
  sudo pacman -S --noconfirm ${emulators[*]}
  sudo pacman -U --noconfirm $HOME/.cache/yay/cemu/*.xz $HOME/.cache/yay/rpcs3-bin/*.xz
}

function osu {
  sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
  sudo pacman -Sy

  cd osuscript
  sudo cp -R /etc/security/limits.conf /etc/security/limits.conf.bak
  echo "@audio - nice -20
  @audio - rtprio 99" | sudo tee /etc/security/limits.conf

  sudo mkdir /etc/pulse/daemon.conf.d
  echo "high-priority = yes
  nice-level = -15

  realtime-scheduling = yes
  realtime-priority = 50

  resample-method = speex-float-0

  default-fragments = 2 # Minimum is 2
  default-fragment-size-msec = 4" | sudo tee /etc/pulse/daemon.conf.d/10-better-latency.conf

  echo "$osu" | sudo tee /usr/bin/osu
  echo "$osukill" | sudo tee /usr/bin/osukill
  sudo chmod +x /usr/bin/osu /usr/bin/osukill

  sink="$(pacmd info |grep 'Default sink name' |cut -c 20-)"

  mkdir $HOME/.config/pulse 2>/dev/null
  cp -R /etc/pulse/default.pa $HOME/.config/pulse/default.pa
  sed -i "s/load-module module-udev-detect.*/load-module module-udev-detect tsched=0 fixed_latency_range=yes/" $HOME/.config/pulse/default.pa

  echo "390xx or nah (y/n)"
  read sel
  if [ $sel == y ]
  then
    sudo pacman -S --noconfirm lib32-nvidia-390xx-utils
  fi
  echo "nvidia or nah (y/n)"
  read nvidia
  if [ $nvidia == y ]
  then
    sudo pacman -S --noconfirm lib32-nvidia-utils
  fi
  sudo pacman -S --noconfirm lib32-alsa-plugins lib32-gnutls lib32-libxcomposite winetricks

  sudo rsync -va --update --delete-after /run/media/$USER/LukeHDD2/Backups/winetricks/ /home/$USER/.cache/winetricks/
  rm -rf $HOME/.wine_osu
  
  export WINEPREFIX="$HOME/.wine_osu"
  export WINEARCH=win32

  winetricks dotnet40
  winetricks gdiplus
  
  echo "Preparations complete. Download and install osu! now? (y/N)"
  read installoss
  if [ $installoss == y ] || [ $installoss == Y ]; then
    curl -L -# 'https://m1.ppy.sh/r/osu!install.exe'
    wine 'osu!install.exe'
  fi
  echo "Script done"
}

function devkitPro {
  echo 'DEVKITPRO=/opt/devkitpro
  DEVKITARM=/opt/devkitpro/devkitARM
  DEVKITPPC=/opt/devkitpro/devkitPPC' | sudo tee -a /etc/environment
  sudo pacman-key --recv F7FD5492264BB9D0
  sudo pacman-key --lsign F7FD5492264BB9D0
  sudo pacman -U https://downloads.devkitpro.org/devkitpro-keyring-r1.787e015-2-any.pkg.tar.xz
  echo '[dkp-libs]
  Server = https://downloads.devkitpro.org/packages
  [dkp-linux]
  Server = https://downloads.devkitpro.org/packages/linux' | sudo tee -a /etc/pacman.conf
  sudo pacman -Sy 3ds-dev switch-dev
}

# ----------------------------------

clear
echo "LukeZGD Arch Post-Install Script"
echo "This script will assume that you have a working Internet connection"
echo
select opt in "Install AUR pkgs w/ yay" "Local AUR pkgs" "Postinstall commands" "VirtualBox" "NVIDIA Optimus+TLP" "NVIDIA 390xx" "osu!" "Emulators" "devkitPro"; do
  case $opt in
    "Install AUR pkgs w/ yay" ) postinstallyay; break;;
    "Local AUR pkgs" ) postinstall; break;;
    "Postinstall commands" ) postinstallcomm; break;;
    "VirtualBox" ) vbox; break;;
    "NVIDIA Optimus+TLP" ) laptop; break;;
    "NVIDIA 390xx" ) 390xx; break;;
    "osu!" ) osu; break;;
    "Emulators" ) emulatorsinstall; break;;
    "devkitPro" ) devkitPro; break;;
  esac
done
