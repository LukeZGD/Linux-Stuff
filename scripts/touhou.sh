#!/bin/bash

#BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
BASEDIR="/mnt/Data/Games/Touhou"

if [[ -n "$1" ]]; then
    launch=$1
else
    launch=$(kdialog --inputbox "Enter number (1-18)" --title "Touhou Launcher")
fi

qdbus org.kde.KWin /Compositor suspend
if [[ $launch == 6 ]]; then
    cd "$BASEDIR/Touhou 6 - The Embodiment of Scarlet Devil"
    wine "$BASEDIR/Touhou 6 - The Embodiment of Scarlet Devil/Touhou06.exe"
elif [[ $launch == 7 ]]; then
    wine "$BASEDIR/Touhou 7 - Perfect Cherry Blossom/vpatch.exe"
elif [[ $launch == 7.5 ]]; then
    wine "$BASEDIR Other/Touhou 7.5 Suimusou ~ Immaterial and Missing Power/th075e.exe"
elif [[ $launch == 8 ]]; then
    wine "$BASEDIR/Touhou 8 - Imperishable Night/vpatch.exe"
elif [[ $launch == 9 ]]; then
    cd "$BASEDIR/Touhou 9 - Phantasmagoria of Flower View"
    wine "$BASEDIR/Touhou 9 - Phantasmagoria of Flower View/Touhou09.exe"
elif [[ $launch == 9.5 ]]; then
    wine "$BASEDIR Other/Touhou 9.5 Bunkachou ~ Shoot the Bullet/th095e.exe"
elif [[ $launch == 10 ]]; then
    wine "$BASEDIR/Touhou 10 - Mountain of Faith/vpatch.exe"
elif [[ $launch == 10.5 ]]; then
    wine "$BASEDIR Other/Touhou 10.5 Hisouten ~ Scarlet Weather Rhapsody/th105e.exe"
elif [[ $launch == 11 ]]; then
    cd "$BASEDIR/Touhou 11 - Subterranean Animism"
    wine "$BASEDIR/Touhou 11 - Subterranean Animism/th11e.exe"
elif [[ $launch == 12 ]]; then
    cd "$BASEDIR/Touhou 12 - Undefined Fantastic Object"
    wine "$BASEDIR/Touhou 12 - Undefined Fantastic Object/th12e.exe"
elif [[ $launch == 12.3 ]]; then
    wine "$BASEDIR Other/Touhou 12.3 Hisoutensoku/th123e.exe"
elif [[ $launch == 12.5 ]]; then
    wine "$BASEDIR Other/Touhou 12.5 Bunkachou ~ Double Spoiler/th125e.exe"
elif [[ $launch == 12.8 ]]; then
    wine "$BASEDIR Other/Touhou 12.8 Yousei Daisensou ~ Touhou Sangetsusei/th128e.exe"
elif [[ $launch == 13 ]]; then
    cd "$BASEDIR/Touhou 13 - Ten Desires"
    wine "$BASEDIR/Touhou 13 - Ten Desires/Touhou13.exe"
elif [[ $launch == 13.5 ]]; then
    wine "$BASEDIR Other/Touhou 13.5 Shinkirou ~ Hopeless Masquerade/th135e.exe"
elif [[ $launch == 14 ]]; then
    cd "$BASEDIR/Touhou 14 - Double-Dealing Character"
    wine "$BASEDIR/Touhou 14 - Double-Dealing Character/Touhou14.exe"
elif [[ $launch == 14.3 ]]; then
    wine "$BASEDIR Other/Touhou 14.3 Danmaku Amanojaku ~ Impossible Spell Card/th143.exe"
elif [[ $launch == 14.5 ]]; then
    wine "$BASEDIR Other/Touhou 14.5 Shinpiroku ~ Urban Legend in Limbo/th145.exe"
elif [[ $launch == 15 ]]; then
    cd "$BASEDIR/Touhou 15 - Legacy of Lunatic Kingdom"
    wine "$BASEDIR/Touhou 15 - Legacy of Lunatic Kingdom/Touhou15.exe"
elif [[ $launch == 15.5 ]]; then
    wine "$BASEDIR Other/Touhou 15.5 Hyouibana ~ Antinomy of Common Flowers/th155.exe"
elif [[ $launch == 16 ]]; then
    cd "$BASEDIR/Touhou 16 - Hidden Star in Four Seasons"
    wine "$BASEDIR/Touhou 16 - Hidden Star in Four Seasons/Touhou16.exe"
elif [[ $launch == 16.5 ]]; then
    wine "$BASEDIR Other/Touhou 16.5 Hifuu Nightmare Diary ~ Violet Detector/th165.exe"
elif [[ $launch == 17 ]]; then
    cd "$BASEDIR/Touhou 17 - Wily Beast and Weakest Creature"
    wine "$BASEDIR/Touhou 17 - Wily Beast and Weakest Creature/Touhou17.exe"
elif [[ $launch == 18 ]]; then
    wine "$BASEDIR/Touhou 18 - Unconnected Marketeers/th18.exe"
elif (( launch < 6 )); then
    echo "Press F12 > F10 to go to fullscreen"
    #sed -i 's|DISK02=|DISK02=Z:\\\mnt\\\Data\\\Games\\\Touhou PC-98\\\'"Touhou$launch.hdi|g" "$BASEDIR/Touhou PC-98/MAIN.INI"
    wine "$BASEDIR/Touhou PC-98/Next.exe"
    #sed -i 's|DISK02=Z:\\\mnt\\\Data\\\Games\\\Touhou PC-98\\\'"Touhou$launch.hdi|DISK02=|g" "$BASEDIR/Touhou PC-98/MAIN.INI"
elif [[ -n "$launch" ]]; then
    kdialog --sorry "Invalid number!" --title "Touhou Launcher"
    exit 1
fi

wineserver -w
qdbus org.kde.KWin /Compositor resume
