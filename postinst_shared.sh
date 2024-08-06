#!/bin/bash

flatpkgs=(
com.github.tchx84.Flatseal
com.github.unrud.VideoDownloader
com.github.wwmm.easyeffects
com.moonlight_stream.Moonlight
com.protonvpn.www
fr.handbrake.ghb
io.github.ungoogled_software.ungoogled_chromium
org.gtk.Gtk3theme.Breeze
org.telegram.desktop
us.zoom.Zoom
)

flatemus=(net.retrodeck.retrodeck)
: '
com.snes9x.Snes9x
io.mgba.mGBA
net.kuribo64.melonDS
net.pcsx2.PCSX2
net.rpcs3.RPCS3
org.DolphinEmu.dolphin-emu
org.duckstation.DuckStation
org.ppsspp.PPSSPP
org.ryujinx.Ryujinx
) '

pipinst() {
    mkdir ~/.config/pip 2>/dev/null
    printf "[global]\nbreak-system-packages = true" > ~/.config/pip/pip.conf
    python3 -m pip install --user -U gallery-dl yt-dlp
}

flatpakemusinst() {
    flatpak install -y flathub "${flatemus[@]}" "$@"
}

hsr() {
    flatpak remote-add --if-not-exists --user launcher.moe https://gol.launcher.moe/gol.launcher.moe.flatpakrepo
    flatpak install -y org.gnome.Platform/x86_64/45
    flatpak install -y launcher.moe moe.launcher.the-honkers-railway-launcher
}

vboxextension() {
    vboxversion=$(curl https://download.virtualbox.org/virtualbox/LATEST-STABLE.TXT)
    vboxextpack="Oracle_VM_VirtualBox_Extension_Pack-$vboxversion.vbox-extpack"
    wget https://download.virtualbox.org/virtualbox/$vboxversion/$vboxextpack
    sudo VBoxManage extpack install --replace $vboxextpack
    rm $vboxextpack
}

wineprefixes() {
    cd $HOME/.cache
    rm -rf wine winetricks
    ln -sf /mnt/Data/$USER/cache/wine
    ln -sf /mnt/Data/$USER/cache/winetricks

    curl -L https://github.com/Winetricks/winetricks/raw/20230212/src/winetricks -o /usr/local/bin/winetricks
    chmod +x /usr/local/bin/winetricks
    preparewineprefix "$HOME/.wine"
    winetricks -q corefonts devenum quartz qasf mfc42 vcrun2010 vcrun2013 vcrun2019 vkd3d win10 wmp9 wmp11
    WINEPREFIX=$HOME/.wine $HOME/Documents/mf-install/mf-install.sh

    preparelutris "$lutrisver"
    preparewineprefix "$HOME/.wine_lutris"
    WINEPREFIX=$HOME/.wine_lutris winetricks -q corefonts devenum quartz qasf vkd3d win10 wmp9 wmp11

    preparelutris "$protonver" "proton"
    preparewineprefix "$HOME/.wine_proton"
    mkdir -p $WINEPREFIX/drive_c/users/steamuser
    cd $WINEPREFIX/drive_c/users/steamuser
    rm -rf 'Saved Games'
    ln -sf $HOME/AppData 'Saved Games'
}
