#!/bin/bash

function fullArea {
  echo 0,0,100,100 | sudo tee /sys/module/veikk/parameters/bounds_map
}

function semiArea {
  echo 0,0,175,175 | sudo tee /sys/module/veikk/parameters/bounds_map
}

function osuArea {
  echo 0,0,345,345 | sudo tee /sys/module/veikk/parameters/bounds_map
}

function init {
  select opt in "Full Area" "Semi-Full Area" "osu! Area"; do
    case $opt in
      "Full Area" ) fullArea; break;;
      "Semi-Full Area" ) semiArea; break;;
      "osu! Area" ) osuArea; break;;
    esac
  done
}

init
