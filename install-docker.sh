#!/bin/bash

set -euo pipefail

sudo pacman -S --noconfirm --needed docker docker-compose
sudo systemctl enable --now docker.service
