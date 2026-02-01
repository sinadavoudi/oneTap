#!/usr/bin/env bash
set -e
echo "Installing oneTap v2..."
apt update -y
apt install -y curl openssh-server jq
chmod +x onetap.sh
echo "✅ Installation complete"
echo "Run: sudo ./onetap.sh"
