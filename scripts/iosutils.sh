#!/bin/bash

compdir="$HOME/Programs/ios-utils"
instdir="/opt/ios-utils"
export PKG_CONFIG_PATH=$instdir/lib/pkgconfig:/usr/lib/$(uname -m)-linux-gnu/pkgconfig:/usr/lib/pkgconfig
export CC=$(which gcc)
export CXX=$(which g++)
if [[ $1 == static ]]; then
    export STATIC_FLAG="--enable-static --disable-shared"
    export BEGIN_LDFLAGS="-all-static -Wl,--allow-multiple-definition"
fi
. /etc/os-release
if [[ -n $UBUNTU_CODENAME || -f "/etc/debian_version" ]]; then
    sudo apt install -y pkg-config libtool automake g++ python-dev-is-python3 libzip-dev libcurl4-openssl-dev cmake libssl-dev libusb-1.0-0-dev libreadline-dev libbz2-dev libpng-dev git ca-certificates
fi

updaterepo() {
    cd $compdir/
    if [[ ! -d $2 ]]; then
        git clone --recursive https://github.com/$1/$2
    fi
    cd $2
    git reset --hard
    git clean -fxd
    git pull
}

compile() {
    if [[ $2 == static ]]; then
        ExtraArgs+=$STATIC_FLAG
    fi
    ExtraArgs+="$3"
    cd $compdir/$1
    ./autogen.sh --prefix="$instdir" $ExtraArgs
    if [[ $2 == static ]]; then
        make LDFLAGS="$BEGIN_LDFLAGS"
    else
        make
    fi
    sudo make install
    make clean
}

mkdir $compdir 2>/dev/null
updaterepo libimobiledevice libplist
updaterepo libimobiledevice libimobiledevice-glue
updaterepo libimobiledevice libusbmuxd
updaterepo libimobiledevice libimobiledevice
updaterepo lzfse lzfse
updaterepo libimobiledevice libirecovery
#updaterepo libimobiledevice libideviceactivation
updaterepo libimobiledevice ideviceinstaller
updaterepo libimobiledevice idevicerestore
updaterepo libimobiledevice ifuse
updaterepo tihmstar libgeneral
updaterepo tihmstar libfragmentzip
updaterepo tihmstar img4tool
updaterepo tihmstar partialZipBrowser
updaterepo 1Conan tsschecker
updaterepo aburgh bsdiff

if [[ $1 == static ]]; then
    updaterepo madler zlib
    cd $compdir/
    aria2c https://sourceware.org/pub/bzip2/bzip2-1.0.8.tar.gz
    aria2c https://tukaani.org/xz/xz-5.2.4.tar.gz
    aria2c https://libzip.org/download/libzip-1.5.1.tar.gz

    cd $compdir/lzfse
    make LDFLAGS="$BEGIN_LDFLAGS"
    sudo make install INSTALL_PREFIX="$instdir"
    make clean

    cd $compdir/
    tar -zxvf bzip2-1.0.8.tar.gz
    cd $compdir/bzip2-1.0.8
    make LDFLAGS="$BEGIN_LDFLAGS" INSTALL_PREFIX="$instdir"
    sudo make install
    make clean

    cd $compdir/zlib
    ./configure --static --prefix="$instdir"
    make LDFLAGS="$BEGIN_LDFLAGS"
    sudo make install
    make clean

    cd $compdir/
    tar -zxvf xz-5.2.4.tar.gz
    cd $compdir/xz-5.2.4
    ./autogen.sh
    ./configure $STATIC_FLAG --prefix="$instdir"
    make LDFLAGS="$BEGIN_LDFLAGS"
    sudo make install
    make clean

    cd $compdir/
    tar -zxvf libzip-1.5.1.tar.gz
    cd $compdir/libzip-1.5.1
    rm -rf new
    mkdir new
    cd new
    cmake .. -DBUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX:PATH="$instdir"
    make LDFLAGS="$BEGIN_LDFLAGS"
    sudo make install
    make clean
fi

is_static=$1
[[ -z $1 ]] && is_static=0
sudo rm -rf $instdir
sudo mkdir $instdir

cd $compdir/lzfse
make LDFLAGS="$BEGIN_LDFLAGS"
sudo make install INSTALL_PREFIX="$instdir"
make clean

compile libplist $is_static --without-cython
compile libimobiledevice-glue $is_static
compile libusbmuxd $is_static
compile libimobiledevice $is_static --without-cython
compile libirecovery $is_static
#compile libideviceactivation $is_static
compile ideviceinstaller $is_static
compile idevicerestore
compile ifuse $is_static

cd $compdir/libgeneral
./autogen.sh --enable-static --disable-shared --prefix="$instdir"
make
sudo make install
make clean

cd $compdir/libfragmentzip
./autogen.sh --enable-static --disable-shared --prefix="$instdir"
make CFLAGS="-I$instdir/include"
sudo make install
make clean

cd $compdir/img4tool
env LDFLAGS="-L$instdir/lib" ./autogen.sh --enable-static --disable-shared --prefix="$instdir"
make
sudo make install
make clean

cd $compdir/partialZipBrowser
./autogen.sh --prefix="$instdir"
make
sudo make install
make clean

cd $compdir/tsschecker
git reset --hard 38dc80a
git clean -fxd
./autogen.sh --prefix="$instdir"
make
sudo make install
make clean

cd $compdir/bsdiff
cd bsdiff
gcc bsdiff.c $HOME/Programs/libbz2.a -o bsdiff
sudo cp bsdiff $instdir/bin
cd ../bspatch
gcc bspatch.c $HOME/Programs/libbz2.a -o bspatch
sudo cp bspatch $instdir/bin

sudo ln -sf $HOME/Programs/AltServer "$instdir/bin"
sudo ln -sf $HOME/Programs/checkra1n "$instdir/bin"
sudo ln -sf $HOME/Programs/futurerestore "$instdir/bin"
sudo ln -sf $HOME/Programs/ideviceactivation "$instdir/bin"
sudo ln -sf $HOME/Programs/netmuxd "$instdir/bin"
sudo ldconfig
echo "Done"
