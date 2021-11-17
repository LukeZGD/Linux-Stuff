#!/bin/bash

sudo apt update
sudo apt install -y avahi-daemon cups hplip printer-driver-gutenprint samba sane-utils
sudo apt upgrade -y
echo "[global]
allow insecure wide links = yes
workgroup = WORKGROUP
netbios name = $(cat /etc/hostname)
security = user
printing = CUPS
rpc_server:spoolss = external
rpc_daemon:spoolssd = fork

[printers]
comment = All Printers
path = /var/spool/samba
browseable = yes
guest ok = yes
writable = no
printable = yes
create mode = 0700
write list = root @adm @wheel $USER

[print$]
comment = Printer Drivers
path = /var/lib/samba/printers
browseable = yes
read only = yes
guest ok = no

[LinuxHost]
comment = Host Share
path = $HOME
valid users = $USER
public = no
writable = yes
printable = no
follow symlinks = yes
wide links = yes" | sudo tee /etc/samba/smb.conf
sudo smbpasswd -a $USER
sudo sed -i "s|Listen localhost:631|Port 631|g" /etc/cups/cupsd.conf
sudo sed -z -i "s|<Location />\n  Order allow,deny|<Location />\n  Order allow,deny\n  Allow @LOCAL|g" /etc/cups/cupsd.conf
sudo sed -z -i "s|<Location /admin>\n  Order allow,deny|<Location /admin>\n  Order allow,deny\n  Allow @LOCAL|g" /etc/cups/cupsd.conf
echo '192.168.1.1/24' | sudo tee -a /etc/sane.d/saned.conf
sudo systemctl enable --now avahi-daemon cups nmbd smbd saned.socket
sudo systemctl restart avahi-daemon cups nmbd smbd saned.socket
