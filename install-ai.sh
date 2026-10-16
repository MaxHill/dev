#!/bin/bash

set -euo pipefail

# Harnesses
curl -fsSL https://opencode.ai/install | bash
mise exec -- npm install -g --ignore-scripts @earendil-works/pi-coding-agent
