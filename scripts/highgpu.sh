#!/bin/bash

card='/sys/class/drm/card0'
if [[ ! -e $card ]]; then
    card='/sys/class/drm/card1'
fi
if [[ ! -e $card ]]; then
    echo "[Error] cannot find gpu"
    exit 1
fi

status="$(cat $card/device/power_dpm_force_performance_level)"
echo "status: $status"
case $1 in
    "on" ) status="auto";;
    "off" | "auto" ) status="on";;
esac
if [[ $status == "auto" ]]; then
    echo "setting high perf gpu to: high"
    echo high | sudo tee $card/device/power_dpm_force_performance_level
    echo 1 | sudo tee $card/device/pp_power_profile_mode
else
    echo "setting high perf gpu to: auto"
    echo auto | sudo tee $card/device/power_dpm_force_performance_level
    echo 3 | sudo tee $card/device/pp_power_profile_mode
fi
