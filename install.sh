#!/usr/bin/env bash
# oneTap v1.1 – Instant SSH Access
# Author: oneTap Project
# License: MIT

set -e

### =========================
### Constants & Globals
### =========================
APP_NAME="oneTap"
APP_VERSION="v1.1.0"
SSH_CONFIG="/etc/ssh/sshd_config"

### =========================
### Helpers
### =========================
require_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "❌ Please run as root"
    exit 1
  fi
}

get_server_ip() {
  curl -s ipv4.icanhazip.com || hostname -I | awk '{print $1}'
}

get_ssh_port() {
  local port
  port=$(grep -i "^Port " "$SSH_CONFIG" | awk '{print $2}' | head -n1)
  echo "${port:-22}"
}

pause() {
  echo ""
  read -p "Press Enter to continue..."
}

user_exists() {
  id "$1" &>/dev/null
}

### =========================
### Core Features
### =========================
create_user() {
  echo ""
  read -p "Enter username: " USERNAME
  read -s -p "Enter password: " PASSWORD
  echo ""

  if user_exists "$USERNAME"; then
    echo "❌ User already exists"
    return
  fi

  useradd -m -s /bin/bash "$USERNAME"
  echo "$USERNAME:$PASSWORD" | chpasswd

  echo "✅ User '$USERNAME' created successfully"
}

list_users() {
  echo ""
  echo "📋 Existing SSH users:"
  awk -F: '$3 >= 1000 {print "- " $1}' /etc/passwd
}

delete_user() {
  echo ""
  read -p "Enter username to delete: " USERNAME

  if ! user_exists "$USERNAME"; then
    echo "❌ User does not exist"
    return
  fi

  userdel -r "$USERNAME"
  echo "🗑 User '$USERNAME' deleted"
}

show_connection_info() {
  echo ""
  read -p "Enter SSH username: " USERNAME

  if ! user_exists "$USERNAME"; then
    echo "❌ User does not exist"
    return
  fi

  SERVER_IP=$(get_server_ip)
  SSH_PORT=$(get_ssh_port)

  echo ""
  echo "========== $APP_NAME :: Connection Info =========="
  echo ""
  echo "Protocol : SSH"
  echo "Server   : $SERVER_IP"
  echo "Port     : $SSH_PORT"
  echo "Username : $USERNAME"
  echo "Password : (the one you set)"
  echo ""
  echo "📱 Shadowrocket (SSH Proxy)"
  echo "  Type       : SSH"
  echo "  Server     : $SERVER_IP"
  echo "  Port       : $SSH_PORT"
  echo "  Username   : $USERNAME"
  echo "  Password   : your password"
  echo "  Encryption : none"
  echo ""
  echo "🔗 Quick Link"
  echo "ssh://$USERNAME@$SERVER_IP:$SSH_PORT"
  echo ""
  echo "==============================================="
}

### =========================
### Menu
### =========================
show_menu() {
  clear
  echo "===================================="
  echo " $APP_NAME — Instant SSH Access"
  echo " Version: $APP_VERSION"
  echo "===================================="
  echo "1) Create SSH user"
  echo "2) List SSH users"
  echo "3) Delete SSH user"
  echo "4) Show client connection info"
  echo "0) Exit"
  echo ""
}

main_loop() {
  while true; do
    show_menu
    read -p "Select an option: " CHOICE
    case "$CHOICE" in
      1) create_user; pause ;;
      2) list_users; pause ;;
      3) delete_user; pause ;;
      4) show_connection_info; pause ;;
      0) exit 0 ;;
      *) echo "❌ Invalid option"; pause ;;
    esac
  done
}

### =========================
### Entry Point
### =========================
require_root
main_loop
