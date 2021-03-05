#!/bin/bash

. /etc/os-release
export PKG_CONFIG_PATH=/opt/ios-utils/lib/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/lib/pkgconfig
[[ ! -z $UBUNTU_CODENAME ]] && sudo apt install -y pkg-config libtool automake g++ python-dev libzip-dev libcurl4-openssl-dev cmake libssl-dev libusb-1.0-0-dev libreadline-dev libbz2-dev libpng-dev git

set -e

sudo rm -rf futurerestore_build
mkdir futurerestore_build
cd futurerestore_build

git clone https://github.com/libimobiledevice/libplist
git clone https://github.com/libimobiledevice/libusbmuxd
git clone https://github.com/libimobiledevice/libimobiledevice 
git clone https://github.com/lzfse/lzfse
git clone https://github.com/libimobiledevice/libirecovery
git clone https://github.com/libimobiledevice/idevicerestore
git clone https://github.com/LukeZGD/libgeneral
git clone https://github.com/LukeZGD/libfragmentzip
git clone https://github.com/LukeZGD/img4tool
git clone https://github.com/LukeZGD/partialZipBrowser
git clone --recursive https://github.com/tihmstar/tsschecker
git clone --recursive https://github.com/marijuanARM/futurerestore
sudo rm -rf /opt/ios-utils
sudo mkdir /opt/ios-utils
cd libplist ; ./autogen.sh --prefix="/opt/ios-utils"; make ; sudo make install ; cd ..
cd libusbmuxd ; ./autogen.sh --prefix="/opt/ios-utils"; make ; sudo make install ; cd ..
cd libimobiledevice ; ./autogen.sh --prefix="/opt/ios-utils"; make ; sudo make install ; cd ..
cd lzfse ; make ; sudo make install INSTALL_PREFIX=/opt/ios-utils ; cd ..
cd libirecovery ; ./autogen.sh --prefix="/opt/ios-utils"; make ; sudo make install ; cd ..
cd idevicerestore ; ./autogen.sh --prefix="/opt/ios-utils"; make ; sudo make install ; cd ..
cd libgeneral ; ./autogen.sh --enable-static --disable-shared --prefix="/opt/ios-utils"; make ; sudo make install ; cd ..
cd libfragmentzip ; ./autogen.sh --enable-static --disable-shared --prefix="/opt/ios-utils"; make CFLAGS="-I/opt/ios-utils/include" ; sudo make install ; cd ..
cd img4tool ; ./autogen.sh --enable-static --disable-shared --prefix="/opt/ios-utils"; make ; sudo make install ; cd ..
cd partialZipBrowser ; ./autogen.sh --prefix="/opt/ios-utils"; make ; sudo make install ; cd ..
cd tsschecker ; ./autogen.sh --prefix="/opt/ios-utils"; make ; sudo make install ; cd ..
cd futurerestore ; ./autogen.sh --prefix="/opt/ios-utils"; make ; sudo make install ; cd ..
sudo ldconfig
echo "Done" 
