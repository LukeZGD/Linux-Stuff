#!/bin/bash

. /etc/os-release
compdir="$HOME/Programs/ios-utils"
instdir="/opt/ios-utils"
export PKG_CONFIG_PATH=$instdir/lib/pkgconfig:/usr/lib/$(uname -m)-linux-gnu/pkgconfig:/usr/lib/pkgconfig
export CC=$(which gcc)
export CXX=$(which g++)
if [[ $1 == static ]]; then
    export STATIC_FLAG="--enable-static --disable-shared"
    export BEGIN_LDFLAGS="-all-static -Wl,--allow-multiple-definition"
fi
[[ -n "$UBUNTU_CODENAME" ]] && sudo apt install -y pkg-config libtool automake g++ python-dev-is-python3 libzip-dev libcurl4-openssl-dev cmake libssl-dev libusb-1.0-0-dev libreadline-dev libbz2-dev libpng-dev git

if [[ ! -d $compdir ]]; then
    mkdir $compdir
    cd $compdir
    git clone https://github.com/libimobiledevice/libplist
    git clone https://github.com/libimobiledevice/libimobiledevice-glue
    git clone https://github.com/libimobiledevice/libusbmuxd
    git clone https://github.com/libimobiledevice/libimobiledevice
    git clone https://github.com/lzfse/lzfse
    git clone https://github.com/libimobiledevice/libirecovery
    git clone https://github.com/libimobiledevice/libideviceactivation
    git clone https://github.com/libimobiledevice/idevicerestore
    git clone https://github.com/libimobiledevice/ifuse
    git clone https://github.com/tihmstar/libgeneral
    git clone https://github.com/tihmstar/libfragmentzip
    git clone https://github.com/tihmstar/img4tool
    git clone https://github.com/tihmstar/partialZipBrowser
    git clone --recursive https://github.com/1Conan/tsschecker
    if [[ $1 == static ]]; then
        git clone https://github.com/madler/zlib
        aria2c https://sourceware.org/pub/bzip2/bzip2-1.0.8.tar.gz
        aria2c https://tukaani.org/xz/xz-5.2.4.tar.gz
        aria2c https://libzip.org/download/libzip-1.5.1.tar.gz
    fi
fi

cd $compdir
cd lzfse ; git reset --hard ; git pull ; cd ..
cd libplist ; git reset --hard ; git pull ; cd ..
cd libimobiledevice-glue ; git reset --hard ; git pull ; cd ..
cd libusbmuxd ; git reset --hard ; git pull ; cd ..
cd libimobiledevice ; git reset --hard ; git pull ; cd ..
cd libirecovery ; git reset --hard ; git pull ; cd ..
cd libideviceactivation ; git reset --hard ; git pull ; cd ..
cd idevicerestore ; git reset --hard ; git pull ; cd ..
cd ifuse ; git reset --hard ; git pull ; cd ..
cd libgeneral ; git reset --hard ; git pull ; cd ..
cd libfragmentzip ; git reset --hard ; git pull ; cd ..
cd img4tool ; git reset --hard ; git pull ; cd ..
cd partialZipBrowser ; git reset --hard ; git pull ; cd ..
cd tsschecker ; git reset --hard ; git pull ; git submodule update --recursive ; cd ..

sudo rm -rf $instdir
sudo mkdir $instdir

if [[ $1 == static ]]; then
    cd lzfse ; make LDFLAGS="$BEGIN_LDFLAGS" ; sudo make install INSTALL_PREFIX=$instdir ; make clean ; cd ..
    tar -zxvf bzip2-1.0.8.tar.gz ; cd bzip2-1.0.8 ; make LDFLAGS="$BEGIN_LDFLAGS" INSTALL_PREFIX=$instdir ; sudo make install ; make clean ; cd ..
    cd zlib ; ./configure --static --prefix="$instdir" ; make LDFLAGS="$BEGIN_LDFLAGS" ; sudo make install ; make clean ; cd ..
    tar -zxvf xz-5.2.4.tar.gz ; cd xz-5.2.4 ; ./autogen.sh ; ./configure $STATIC_FLAG --prefix="$instdir" ; make LDFLAGS="$BEGIN_LDFLAGS" ; sudo make install ; make clean ; cd ..
    tar -zxvf libzip-1.5.1.tar.gz ; cd libzip-1.5.1 ; rm -rf build ; mkdir build ; cd build ; cmake .. -DBUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX:PATH="$instdir" ; make LDFLAGS="$BEGIN_LDFLAGS" ; sudo make install ; make clean ; cd ../..
    cd libplist ; ./autogen.sh --prefix="$instdir" $STATIC_FLAG ; make LDFLAGS="$BEGIN_LDFLAGS" ; sudo make install ; make clean ; cd ..
    cd libimobiledevice-glue ; ./autogen.sh --prefix="$instdir" $STATIC_FLAG ; make LDFLAGS="$BEGIN_LDFLAGS" ; sudo make install ; make clean ; cd ..
    cd libusbmuxd ; ./autogen.sh --prefix="$instdir" $STATIC_FLAG ; make LDFLAGS="$BEGIN_LDFLAGS" ; sudo make install ; make clean ; cd ..
    cd libimobiledevice ; ./autogen.sh --prefix="$instdir" $STATIC_FLAG --without-cython ; make LDFLAGS="$BEGIN_LDFLAGS" ; sudo make install ; make clean ; cd ..
    cd libirecovery ; ./autogen.sh --prefix="$instdir" $STATIC_FLAG ; make LDFLAGS="$BEGIN_LDFLAGS" ; sudo make install ; make clean ; cd ..
    cd libideviceactivation ; ./autogen.sh --prefix="$instdir" $STATIC_FLAG ; make LDFLAGS="$BEGIN_LDFLAGS" ; sudo make install ; make clean ; cd ..
    cd idevicerestore ; ./autogen.sh --prefix="$instdir" ; make ; sudo make install ; make clean ; cd ..
    cd ifuse ; ./autogen.sh --prefix="$instdir" ; make ; sudo make install ; make clean ; cd ..
    cd libgeneral ; ./autogen.sh --enable-static --disable-shared --prefix="$instdir" ; make ; sudo make install ; make clean ; cd ..
    cd libfragmentzip ; ./autogen.sh --enable-static --disable-shared --prefix="$instdir" ; make CFLAGS="-I$instdir/include" ; sudo make install ; make clean ; cd ..
    cd img4tool ; LDFLAGS="-L$instdir/lib" ./autogen.sh --enable-static --disable-shared --prefix="$instdir" ; make ; sudo make install ; make clean ; cd ..
    cd partialZipBrowser ; ./autogen.sh --prefix="$instdir" ; make ; sudo make install ; make clean ; cd ..
    cd tsschecker ; git reset 38dc80a ; git reset --hard ; ./autogen.sh --prefix="$instdir" ; make ; sudo make install ; make clean ; cd ..
else
    cd libplist ; ./autogen.sh --prefix="$instdir"; make ; sudo make install ; make clean ; cd ..
    cd libimobiledevice-glue ; ./autogen.sh --prefix="$instdir"; make ; sudo make install ; make clean ; cd ..
    cd libusbmuxd ; ./autogen.sh --prefix="$instdir"; make ; sudo make install ; make clean ; cd ..
    cd libimobiledevice ; ./autogen.sh --prefix="$instdir"; make ; sudo make install ; make clean ; cd ..
    cd lzfse ; make ; sudo make install INSTALL_PREFIX=$instdir ; make clean ; cd ..
    cd libirecovery ; ./autogen.sh --prefix="$instdir"; make ; sudo make install ; make clean ; cd ..
    cd libideviceactivation ; ./autogen.sh --prefix="$instdir"; make ; sudo make install ; make clean ; cd ..
    cd idevicerestore ; ./autogen.sh --prefix="$instdir"; make ; sudo make install ; make clean ; cd ..
    cd ifuse ; ./autogen.sh --prefix="$instdir"; make ; sudo make install ; make clean ; cd ..
    cd libgeneral ; ./autogen.sh --enable-static --disable-shared --prefix="$instdir"; make ; sudo make install ; make clean ; cd ..
    cd libfragmentzip ; ./autogen.sh --enable-static --disable-shared --prefix="$instdir"; make CFLAGS="-I$instdir/include" ; sudo make install ; make clean ; cd ..
    cd img4tool ; LDFLAGS="-L$instdir/lib" ./autogen.sh --enable-static --disable-shared --prefix="$instdir"; make ; sudo make install ; make clean ; cd ..
    cd partialZipBrowser ; ./autogen.sh --prefix="$instdir"; make ; sudo make install ; make clean ; cd ..
    cd tsschecker ; git reset 38dc80a ; git reset --hard ; ./autogen.sh --prefix="$instdir" ; make ; sudo make install ; make clean ; cd ..
fi
sudo ln -sf $HOME/Programs/AltServer /opt/ios-utils/bin
sudo ln -sf $HOME/Programs/checkra1n /opt/ios-utils/bin
sudo ln -sf $HOME/Programs/futurerestore /opt/ios-utils/bin
sudo ln -sf $HOME/Programs/netmuxd /opt/ios-utils/bin
sudo ldconfig
echo "Done"
