#!/bin/sh

set -e

yay -S --needed --noconfirm dropbox
yay -S --needed --noconfirm libreoffice-still
yay -S --needed --noconfirm betterbird-bin 

yay -S --needed --noconfirm localsend-bin
sudo ufw allow 53317/tcp comment 'LocalSend'
sudo ufw allow 53317/udp comment 'LocalSend'
