#!/bin/sh

set -eu

yay -S --noconfirm --needed iwd impala 
sudo install -d -m 755 /etc/systemd/network

NETWORK_CONFIG=/etc/systemd/network/25-wireless.network
previous_checksum=
if sudo test -f "$NETWORK_CONFIG"; then
    previous_checksum=$(sudo sha256sum "$NETWORK_CONFIG")
fi

sudo tee "$NETWORK_CONFIG" > /dev/null <<EOF
   [Match]
   Name=wl*

   [Network]
   DHCP=yes
   IgnoreCarrierLoss=3s
EOF

# Disable anything that competes
NETWORK_MANAGER_SERVICE="NetworkManager.service";
if systemctl cat "$NETWORK_MANAGER_SERVICE" > /dev/null 2>&1; then
    sudo systemctl disable --now "$NETWORK_MANAGER_SERVICE"
fi

WPA_SUPPLICANT_SERVICE="wpa_supplicant.service";
if systemctl cat "$WPA_SUPPLICANT_SERVICE" > /dev/null 2>&1; then
    sudo systemctl disable --now "$WPA_SUPPLICANT_SERVICE"
fi

# Enable the stack
sudo systemctl enable --now systemd-resolved

# Programs need to turn names such as archlinux.org into IP addresses. 
# Many consult /etc/resolv.conf to find out which DNS server to ask.
sudo ln -sfn /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

sudo systemctl enable --now iwd
sudo systemctl enable --now systemd-networkd
if [ "$previous_checksum" != "$(sudo sha256sum "$NETWORK_CONFIG")" ]; then
    sudo systemctl restart systemd-networkd
fi


