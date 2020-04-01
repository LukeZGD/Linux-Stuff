#!/bin/bash

packages=(
checkra1n-cli
ffmpeg-compat-57
gconf
libirecovery-git
libsndio-61-compat
ncurses5-compat-libs
python2-twodict-git

adapta-backgrounds
adwaita-qt
chromium-widevine
etcher-bin
gallery-dl
github-desktop-bin
qdirstat
woeusb
wps-office
youtube-dl-gui-git
)

pacman=(
fish
linux54-headers
nano-syntax-highlighting
neofetch

audacious
audacity
breeze-gtk
ffmpegthumbnailer
fluidsynth
handbrake
kdenlive
kodi
krita
mpv
nemo
obs-studio
okteta
pinta
viewnior

gnome-disk-utility
gnome-keyring
gparted
gsmartcontrol
ifuse
jre8-openjdk
kodi-addon-inputstream-adaptive
krdc
libreoffice-still
libressl
love
freerdp
seahorse
testdisk
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

paccache=/var/cache/pacman/pkg

function installpac {
  git clone https://aur.archlinux.org/$1.git
  cd $1
  makepkg -si
  cd ..
  rm -rf $1
}

function postinstall {
  for package in "${packages[@]}"
  do
    sudo pacman -U --noconfirm $paccache/${package}*.xz
  done
  installpac libimobiledevice-git
  sudo pacman -U --noconfirm $paccache/idevicerestore-git*.xz
}

function postinstallpamac {
  pamac install ${packages[@]}
  installpac libimobiledevice-git
  pamac install idevicerestore-git
}

function postinstallcomm {
echo "[Log] Install packages"
sudo pacman -S --noconfirm ${pacman[*]}
sudo pacman -R --noconfirm appimagelauncher gwenview kget vlc yakuake
[ -e $HOME/Documents/packages/ ] && sudo pacman -U --noconfirm $HOME/Documents/packages/* #for veikk drivers and fonts
echo "[Log] set fish as default shell"
sudo usermod -aG audio -s /usr/bin/fish $USER
echo "[Input] Create 2nd user account? (with no wheel/sudo) (y/n)"
read userc2
if [ $userc2 == y ] || [ $userc2 == Y ]; then
  echo "[Input] Enter username"
  read username2
  echo "[Log] Creating user $username2"
  sudo useradd -m -g users -G audio -s /usr/bin/fish $username2
  echo "[Log] Running passwd $username2"
  sudo passwd $username2
fi
echo "[Log] Configure stuff"
echo 'include "/usr/share/nano/*.nanorc"
include "/usr/share/nano-syntax-highlighting/*.nanorc"' | sudo tee /etc/nanorc
sudo sed -i "s/#Color/Color/" /etc/pacman.conf
sudo sed -i "s/#TotalDownload/TotalDownload/" /etc/pacman.conf
echo "[Log] Configuring rc-local"
echo '[Unit]
Description=/etc/rc.local compatibility

[Service]
Type=oneshot
ExecStart=/etc/rc.local
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target' | sudo tee /usr/lib/systemd/system/rc-local.service
echo '#!/bin/bash
echo 0,0,345,345 | sudo tee /sys/module/veikk/parameters/bounds_map
exit 0' | sudo tee /etc/rc.local
sudo chmod +x /etc/rc.local
sudo systemctl enable rc-local
#gsettings set org.nemo.desktop font 'Cantarell Regular 10'
gsettings set org.nemo.preferences size-prefixes 'base-2'
#xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/logind-handle-power-key -n -t bool -s true
#xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/logind-handle-lid-switch -n -t bool -s true
#autocreate "light-locker"
#autocreate "xfce4-clipman"
#echo 'export QT_STYLE_OVERRIDE=adwaita-dark' | tee -a $HOME/.xprofile
echo '--ignore-gpu-blacklist
--enable-gpu-rasterization
--enable-native-gpu-memory-buffers
--enable-zero-copy
--disable-gpu-driver-bug-workarounds' | tee $HOME/.config/chromium-flags.conf
sudo timedatectl set-ntp true
sudo timedatectl set-local-rtc 1 --adjust-system-clock
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
Hidden=false" | tee $HOME/.config/autostart/$1.desktop
}

function vbox {
  sudo pacman -S --noconfirm virtualbox virtualbox-host-dkms virtualbox-guest-iso
  pamac install virtualbox-ext-oracle
  sudo usermod -aG vboxusers $USER
  sudo modprobe vboxdrv
}

function laptop {
  #sudo pacman -S --noconfirm bbswitch-dkms nvidia-lts nvidia-settings tlp
  #sudo pacman -U --noconfirm $paccache/optimus-manager*.xz $paccache/optimus-manager-qt*.xz
  #sudo systemctl enable tlp
  pamac install optimus-manager optimus-manager-qt
  sudo sed -i '/DisplayCommand/s/^/#/g' /etc/sddm.conf
  sudo sed -i '/DisplayStopCommand/s/^/#/g' /etc/sddm.conf
}

function 390xx {
  sudo pacman -S --noconfirm nvidia-390xx-lts nvidia-390xx-settings
}

function emulatorsinstall {
  sudo pacman -S --noconfirm desmume dolphin-emu fceux mgba-qt mupen64plus ppsspp snes9x-gtk
  pamac install citra-qt-bin cemu pcsx2-git rpcs3-bin
}

function osu {
  sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
  sudo pacman -Sy
  
  sudo cp /etc/security/limits.conf /etc/security/limits.conf.bak
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

  echo "390xx or nah (y/N)"
  read sel
  if [[ $sel == y ]]; then
    sudo pacman -S --noconfirm lib32-nvidia-390xx-utils
  fi
  echo "nvidia or nah (y/N)"
  read nvidia
  if [[ $nvidia == y ]]; then
    sudo pacman -S --noconfirm lib32-nvidia-utils
  fi
  sudo pacman -S --noconfirm lib32-alsa-plugins lib32-gnutls lib32-libxcomposite winetricks

  sudo rsync -va --update --delete-after /run/media/$USER/LukeHDD2/Backups/winetricks/ $HOME/.cache/winetricks/
  rm -rf $HOME/.wine_osu
  
  export WINEPREFIX="$HOME/.wine_osu"
  export WINEARCH=win32

  winetricks dotnet40
  winetricks gdiplus
  
  sudo usermod -aG audio $USER
  echo "Preparations complete. Download and install osu! now? (y/N)"
  read installoss
  if [ $installoss == y ] || [ $installoss == Y ]; then
    curl -L -# 'https://m1.ppy.sh/r/osu!install.exe'
    wine 'osu!install.exe'
  fi
  echo "Script done"
}

function devkitPro {
  echo 'export DEVKITPRO=/opt/devkitpro
  export DEVKITARM=/opt/devkitpro/devkitARM
  export DEVKITPPC=/opt/devkitpro/devkitPPC' | tee -a $HOME/.profile
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
select opt in "Install pamac" "Install AUR pkgs cache" "Install AUR pkgs pamac" "Postinstall commands" "VirtualBox" "NVIDIA Optimus+TLP" "NVIDIA 390xx" "osu!" "Emulators" "devkitPro"; do
  case $opt in
    "Install pamac" ) installpac pamac-aur; break;;
    "Install AUR pkgs cache" ) postinstall; break;;
    "Install AUR pkgs pamac" ) postinstallpamac; break;;
    "Postinstall commands" ) postinstallcomm; break;;
    "VirtualBox" ) vbox; break;;
    "NVIDIA Optimus+TLP" ) laptop; break;;
    "NVIDIA 390xx" ) 390xx; break;;
    "osu!" ) osu; break;;
    "Emulators" ) emulatorsinstall; break;;
    "devkitPro" ) devkitPro; break;;
  esac
done
