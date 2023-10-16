#!/bin/bash
trap 'kill $netmuxdPID 2>/dev/null' EXIT
trap 'kill $netmuxdPID 2>/dev/null; exit 1' INT TERM

export ALTSERVER_ANISETTE_SERVER=http://127.0.0.1:6969
AltServer="env ALTSERVER_ANISETTE_SERVER=$ALTSERVER_ANISETTE_SERVER $HOME/Programs/AltServer"

for i in "$@"; do
    if [[ $i == "netmuxd" ]]; then
        echo "netmuxd argument detected"
        netmuxd="$HOME/Programs/netmuxd"
        export USBMUXD_SOCKET_ADDRESS=127.0.0.1:27015
    fi
done

help() {
    echo "Usage: $(basename $0) <operation> [...] [netmuxd]"
    echo "Operations:
    {help}
    {install} [Apple ID] [Password] [IPA Path]
    {pull}
    {server}"
}

prepare() {
    if [[ ! $(systemctl is-active --quiet docker) ]]; then
        echo "docker is not running. starting docker"
        sudo systemctl start docker
    fi
    echo "running anisette"
    docker run -d -v lib_cache:/opt/lib/ --restart=always -p 6969:6969 --name anisette dadoum/anisette-server:latest
    while [[ $ready != 1 ]]; do
        echo "waiting for anisette"
        [[ $(curl 127.0.0.1:6969) ]] && ready=1
        sleep 1
    done
    [[ -z $netmuxd ]] && return
    echo "running netmuxd"
    netmuxd --disable-unix --host 127.0.0.1 &
    netmuxdPID=$!
}

pull() {
    docker pull nyamisty/alt_anisette_server
}

server() {
    prepare
    echo "running altserver"
    $AltServer
}

install() {
    prepare
    echo "Installing: $3"
    echo "Apple ID: $2"
    read -s -p "Password: " password
    cd $HOME
    $AltServer -u $(ideviceinfo -k UniqueDeviceID) -a "$2" -p "$password" "$3"
}

if [[ ! $* ]]; then
    echo "[Error] No arguments"
    help
    exit 1
fi

echo "Running AltServerHelper in $1 mode"
$1 "$@"
