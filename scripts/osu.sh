#!/bin/bash
export WINEPREFIX="$HOME/.wine_osu"
export WINEARCH="win32"

drirc='
<device screen="0" driver="dri2">
    <application name="Default">
        <option name="vblank_mode" value="0"/>
    </application>
</device>'

function osu {
  if [ $USER == lukee ]; then
    xrandr --output DVI-I-1 --mode 1440x900 --rate 74.98 2>/dev/null
    xrandr --output VGA-1 --mode 1440x900 --rate 74.98 2>/dev/null
    xrandr --output VGA-0 --mode 1440x900 --rate 74.98 2>/dev/null
    xrandr --output eDP1 --mode 1400x900 2>/dev/null
    xrandr --output eDP-1 --mode 1400x900 2>/dev/null
    xrandr --output eDP-1-1 --mode 1400x900 2>/dev/null
    xrandr --output HDMI-1 --mode 1440x900 --rate 74.98 2>/dev/null
    xrandr --output HDMI-1-1 --mode 1440x900 --rate 74.98 2>/dev/null
  fi
  
  if [[ $1 == "lazer" ]]; then
    $HOME/osu/osu.AppImage
  else
    echo "$drirc" > $HOME/.drirc
    bash -c osukill
    cd $HOME/osu # Or wherever you installed osu! in
    wine osu!.exe "$@"
    bash -c osukill
    rm -f $HOME/.drirc
  fi
  
  if [ $USER == lukee ]; then
    xrandr --output DVI-I-1 --mode 1920x1080 2>/dev/null
    xrandr --output VGA-1 --mode 1920x1080 2>/dev/null
    xrandr --output VGA-0 --mode 1920x1080 2>/dev/null
    xrandr --output eDP1 --mode 1920x1080 2>/dev/null
    xrandr --output eDP-1 --mode 1920x1080 2>/dev/null
    xrandr --output eDP-1-1 --mode 1920x1080 2>/dev/null
    xrandr --output HDMI-1 --mode 1920x1080 2>/dev/null
    xrandr --output HDMI-1-1 --mode 1920x1080 2>/dev/null
  fi
}

function random {
  for i in {1..4}; do
    osu "$HOME/osu/oss/$(ls $HOME/osu/oss/ | shuf -n 1)"
  done
}

function remove {
  osslist=$(ls $HOME/osu/oss/ | sed -e 's/\.osz$//')
  osulist=$(ls $HOME/osu/Songs)
  ossremoved=$(comm -12 $osslist $osulist)
  sed -i 's/$/.osz/' $ossremoved
  sed -i 's/^/oss\//' $ossremoved
  cat $ossremoved | xargs -d '\n' rm -rf
  cat $ossremoved
}

function update {
  cd $HOME/osu
  current=$(cat osu.AppImage.version 2>/dev/null)
  latest=$(curl -s https://api.github.com/repos/ppy/osu/releases/latest | grep "tag_name" | cut -d : -f 2,3)
  if [[ $latest != $current ]]; then
    rm osu.AppImage* 2>/dev/null
    curl -s https://api.github.com/repos/ppy/osu/releases/latest | grep "/osu.AppImage" | cut -d : -f 2,3 | tr -d \" | wget -nv --show-progress -i -
    chmod +x osu.AppImage
    echo "$latest" > osu.AppImage.version
    echo "Updated"
  else
    echo "Currently updated, nothing to do"
  fi
}

function osuinstall {
  sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf  
  sudo cp /etc/security/limits.conf /etc/security/limits.conf.bak
  echo "@audio - nice -20
  @audio - rtprio 99" | sudo tee /etc/security/limits.conf
  sudo mkdir /etc/pulse/daemon.conf.d 2>/dev/null
  echo "high-priority = yes
  nice-level = -15

  realtime-scheduling = yes
  realtime-priority = 50

  resample-method = speex-float-0

  default-sample-format = s32le
  default-sample-rate = 48000
  alternate-sample-rate = 48000
  default-sample-channels = 2

  default-fragments = 2
  default-fragment-size-msec = 4" | sudo tee /etc/pulse/daemon.conf.d/10-better-latency.conf

  sudo cp $(dirname $(type -p $0))/osu.sh /usr/bin/osu
  sudo chmod +x /usr/bin/osu

  mkdir $HOME/.config/pulse 2>/dev/null
  cp -R /etc/pulse/default.pa $HOME/.config/pulse/default.pa
  sed -i "s/load-module module-udev-detect.*/load-module module-udev-detect tsched=0 fixed_latency_range=yes/" $HOME/.config/pulse/default.pa
  
  sudo pacman -S --noconfirm --needed lib32-alsa-plugins lib32-gnutls lib32-libxcomposite winetricks
  rm -rf $HOME/.wine_osu
  
  winetricks dotnet40
  winetricks gdiplus
  
  mkdir $HOME/osu 2>/dev/null
  cd osu
  echo "Preparations complete. Download and install osu! now? (y/N)"
  read osudl
  if [[ $osudl == y ]] || [[ $osudl == Y ]]; then
    curl -L -# 'https://m1.ppy.sh/r/osu!install.exe'
    wine 'osu!install.exe'
  fi
  echo "Script done"
}

if [[ $1 == "random" ]]; then
  random
elif [[ $1 == "remove" ]]; then
  remove
elif [[ $1 == "update" ]]; then
  update
elif [[ $1 == "lazer" ]]; then
  osu lazer
elif [[ $1 == "kill" ]]; then
  wineserver -k
  exit
elif [[ $1 == "help" ]]; then
  echo "Usage: $0 <operation> [...]"
  echo "Operations:
    osu {help}
    osu {install}
    osu {kill}
    osu {lazer}
    osu {random}
    osu {remove}
    osu {update}"
elif [[ $1 == "install" ]]; then
  osuinstall
else
  osu "$@"
fi
