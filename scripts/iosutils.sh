#!/bin/bash

. /etc/os-release
compdir="$HOME/Programs/ios-utils"
instdir="/opt/ios-utils"
export PKG_CONFIG_PATH=$instdir/lib/pkgconfig:/usr/lib/$(uname -m)-linux-gnu/pkgconfig:/usr/lib/pkgconfig
export CC=$(which gcc)
export CXX=$(which g++)
[[ ! -z $UBUNTU_CODENAME ]] && sudo apt install -y pkg-config libtool automake g++ python-dev-is-python3 libzip-dev libcurl4-openssl-dev cmake libssl-dev libusb-1.0-0-dev libreadline-dev libbz2-dev libpng-dev git

set -e

#sudo rm -rf $compdir

if [[ -d $compdir ]]; then
    cd $compdir
    cd libplist ; git reset --hard ; git pull ; cd ..
    cd libusbmuxd ; git reset --hard ; git pull ; cd ..
    cd libimobiledevice ; git reset --hard ; git pull ; cd ..
    cd lzfse ; git reset --hard ; git pull ; cd ..
    cd libirecovery ; git reset --hard ; git pull ; cd ..
    cd libideviceactivation ; git reset --hard ; git pull ; cd ..
    cd idevicerestore ; git reset --hard ; git pull ; cd ..
    cd libgeneral ; git reset --hard ; git pull ; cd ..
    cd libfragmentzip ; git reset --hard ; git pull ; cd ..
    cd img4tool ; git reset --hard ; git pull ; cd ..
    cd partialZipBrowser ; git reset --hard ; git pull ; cd ..
    cd tsschecker ; git reset --hard ; git pull ; git submodule update --recursive ; cd ..
    #cd futurerestore ; git reset --hard ; git pull ; git submodule update --recursive ; cd ..
else
    mkdir $compdir
    cd $compdir

    git clone https://github.com/libimobiledevice/libplist
    git clone https://github.com/libimobiledevice/libusbmuxd
    git clone https://github.com/libimobiledevice/libimobiledevice 
    git clone https://github.com/lzfse/lzfse
    git clone https://github.com/libimobiledevice/libirecovery
    git clone https://github.com/libimobiledevice/libideviceactivation
    git clone https://github.com/libimobiledevice/idevicerestore
    git clone https://github.com/tihmstar/libgeneral
    git clone https://github.com/tihmstar/libfragmentzip
    git clone https://github.com/tihmstar/img4tool
    git clone https://github.com/tihmstar/partialZipBrowser
    git clone --recursive https://github.com/tihmstar/tsschecker
    #git clone --recursive https://github.com/m1stadev/futurerestore
fi

sudo rm -rf $instdir
sudo mkdir $instdir

cd libplist ; ./autogen.sh --prefix="$instdir"; make ; sudo make install ; make clean ; cd ..
cd libusbmuxd ; ./autogen.sh --prefix="$instdir"; make ; sudo make install ; make clean ; cd ..
cd libimobiledevice ; ./autogen.sh --prefix="$instdir"; make ; sudo make install ; make clean ; cd ..
cd lzfse ; make ; sudo make install INSTALL_PREFIX=$instdir ; make clean ; cd ..
cd libirecovery ; ./autogen.sh --prefix="$instdir"; make ; sudo make install ; make clean ; cd ..
cd libideviceactivation ; ./autogen.sh --prefix="$instdir"; make ; sudo make install ; make clean ; cd ..
cd idevicerestore ; ./autogen.sh --prefix="$instdir"; make ; sudo make install ; make clean ; cd ..
cd libgeneral ; ./autogen.sh --enable-static --disable-shared --prefix="$instdir"; make ; sudo make install ; make clean ; cd ..
cd libfragmentzip ; ./autogen.sh --enable-static --disable-shared --prefix="$instdir"; make CFLAGS="-I$instdir/include" ; sudo make install ; make clean ; cd ..
cd img4tool ; LDFLAGS="-L$instdir/lib" ./autogen.sh --enable-static --disable-shared --prefix="$instdir"; make ; sudo make install ; make clean ; cd ..
cd partialZipBrowser ; ./autogen.sh --prefix="$instdir"; make ; sudo make install ; make clean ; cd ..
cd tsschecker ; ./autogen.sh --prefix="$instdir"; make ; sudo make install ; make clean ; cd ..
#cd futurerestore ; git checkout test ; git reset --hard ; git submodule update --recursive ; ./autogen.sh --prefix="$instdir"; make ; sudo make install ; make clean ; cd ..

sudo ldconfig
echo "Done"
