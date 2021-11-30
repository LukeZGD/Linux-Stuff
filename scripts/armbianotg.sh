#!/bin/sh
# turn on microusb otg port in armbian (work as host)
# solution from https://forum.armbian.com/topic/4814-orange-pi-one-usb-otg/

#FILE=$1
FILE="/boot/dtb/sun8i-h3-orangepi-one.dtb"
BACKUP="$FILE.bak"
SRC="tmp.dts"

trap "rm $SRC" INT TERM EXIT

sudo cp "$FILE" "$BACKUP"
dtc -I dtb -O dts -o "$SRC" "$FILE"
sed -i -e 's/dr_mode = "otg";/dr_mode = "host";/g' "$SRC"
sudo dtc -I dts -O dtb -o "$FILE" "$SRC"
