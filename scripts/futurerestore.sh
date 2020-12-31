#!/bin/bash

mkdir build
cd build
sudo apt install -y libtool automake g++ python-dev libzip-dev libcurl4-openssl-dev cmake libssl-dev libusb-1.0-0-dev libreadline-dev libbz2-dev libpng-dev
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig

git clone https://github.com/libimobiledevice/libplist
git clone https://github.com/libimobiledevice/libusbmuxd
git clone https://github.com/libimobiledevice/libimobiledevice
cd libplist && ./autogen.sh && make && sudo make install && cd ..
cd libusbmuxd && ./autogen.sh && make && sudo make install && cd ..
cd libimobiledevice && ./autogen.sh && make && sudo make install && cd ..

git clone https://github.com/lzfse/lzfse
git clone https://github.com/libimobiledevice/libirecovery
git clone https://github.com/libimobiledevice/idevicerestore
git clone https://github.com/LukeZGD/libgeneral
git clone https://github.com/LukeZGD/libfragmentzip
git clone https://github.com/LukeZGD/img4tool
git clone https://github.com/LukeZGD/partialZipBrowser
git clone --recursive https://github.com/tihmstar/tsschecker
git clone --recursive https://github.com/marijuanARM/futurerestore
cd lzfse && make && sudo make install && cd ..
cd libirecovery && ./autogen.sh && make && sudo make install && cd ..
cd idevicerestore && ./autogen.sh && make && sudo make install && cd ..
cd libgeneral && ./autogen.sh --enable-static --disable-shared && make && sudo make install && cd ..
cd libfragmentzip && ./autogen.sh --enable-static --disable-shared && make && sudo make install && cd ..
cd img4tool && ./autogen.sh --enable-static --disable-shared && make && sudo make install && cd ..
cd partialZipBrowser && ./autogen.sh && make && sudo make install && cd ..
cd tsschecker && ./autogen.sh && make && sudo make install && cd ..
cd futurerestore  && ./autogen.sh && make && sudo make install && cd ..
cd /usr/local/bin
sudo mkdir bin
sudo mv futurerestore bin/futurerestore
sudo mv idevicerestore bin/idevicerestore
sudo mv tsschecker bin/tsschecker
echo '#!/bin/sh
LD_LIBRARY_PATH=/usr/local/lib /usr/local/bin/bin/futurerestore $@; exit $?' | sudo tee futurerestore
echo '#!/bin/sh
LD_LIBRARY_PATH=/usr/local/lib /usr/local/bin/bin/idevicerestore $@; exit $?' | sudo tee idevicerestore
echo '#!/bin/sh
LD_LIBRARY_PATH=/usr/local/lib /usr/local/bin/bin/tsschecker $@; exit $?' | sudo tee tsschecker
sudo chmod +x futurerestore idevicerestore tsschecker
echo "Done" 
