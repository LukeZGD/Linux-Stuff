#!/bin/bash
[[ -z $1 ]] && read -p "Name of VM?: " macosvm || macosvm="$1"
VBoxManage modifyvm "$macosvm" --cpuidset 00000001 000106e5 00100800 0098e3fd bfebfbff
VBoxManage setextradata "$macosvm" "VBoxInternal/Devices/efi/0/Config/DmiSystemProduct" "iMac11,3"
VBoxManage setextradata "$macosvm" "VBoxInternal/Devices/efi/0/Config/DmiSystemVersion" "1.0"
VBoxManage setextradata "$macosvm" "VBoxInternal/Devices/efi/0/Config/DmiBoardProduct" "Iloveapple"
VBoxManage setextradata "$macosvm" "VBoxInternal/Devices/smc/0/Config/DeviceKey" "ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc"
VBoxManage setextradata "$macosvm" "VBoxInternal/Devices/smc/0/Config/GetKeyFromRealSMC" 1
VBoxManage modifyvm "$macosvm" --cpu-profile "Intel Core i7-6700K"
#VBoxManage setextradata "$macosvm" "VBoxInternal/Devices/efi/0/Config/DmiSystemProduct" "MacBookPro15,1"
#VBoxManage setextradata "$macosvm" "VBoxInternal/Devices/efi/0/Config/DmiBoardProduct" "Mac-551B86E5744E2388"
#VBoxManage setextradata "$macosvm" "VBoxInternal/TM/TSCMode" "RealTSCOffset"
#VBoxManage setextradata "$macosvm" VBoxInternal2/EfiGopMode 4
#VBoxManage setextradata "$macosvm" "VBoxInternal/Devices/VMMDev/0/Config/GetHostTimeDisabled" 1
#VBoxManage modifyvm "$macosvm" --biossystemtimeoffset -31536000000
