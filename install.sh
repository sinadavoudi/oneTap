#!/usr/bin/env bash
set -e

APP_NAME="oneTap"
STATE_DIR="/opt/onetap"
KEYS_DIR="$STATE_DIR/keys"
USERS_DIR="$STATE_DIR/users"
PORT=22

require_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "Please run as root."
    exit 1
  fi
}

init_dirs() {
  mkdir -p "$KEYS_DIR" "$USERS_DIR"
  chmod 700 "$STATE_DIR" "$KEYS_DIR" "$USERS_DIR"
}

pause() { read -p "Press Enter to continue..."; }

have_domain_prompt() {
  echo "Do you have a domain?"
  echo "1) Yes"
  echo "2) No (use server IP)"
  read -p "Select [1-2]: " DSEL
  if [[ "$DSEL" == "1" ]]; then
    read -p "Enter domain name: " DOMAIN
  else
    DOMAIN="$(curl -s https://api.ipify.org || hostname -I | awk '{print $1}')"
  fi
}

create_profile() {
  read -p "Profile name (leave empty for auto): " PNAME
  if [[ -z "$PNAME" ]]; then
    PNAME="tap_$(tr -dc a-f0-9 </dev/urandom | head -c 6)"
  fi

  USER_HOME="$USERS_DIR/$PNAME"
  mkdir -p "$USER_HOME/.ssh"
  chmod 700 "$USER_HOME" "$USER_HOME/.ssh"

  ssh-keygen -t ed25519 -N "" -f "$KEYS_DIR/$PNAME" >/dev/null

  PUBKEY="$(cat "$KEYS_DIR/$PNAME.pub")"
  echo "$PUBKEY" > "$USER_HOME/.ssh/authorized_keys"
  chmod 600 "$USER_HOME/.ssh/authorized_keys"

  useradd -M -d "$USER_HOME" -s /usr/sbin/nologin "$PNAME"
  chown -R "$PNAME:$PNAME" "$USER_HOME"

  have_domain_prompt

  echo ""
  echo "Profile created: $PNAME"
  echo "--------------------------------"
  echo "Private key: $KEYS_DIR/$PNAME"
  echo "Connect with:"
  echo "ssh -i $KEYS_DIR/$PNAME -N -D 1080 $PNAME@$DOMAIN -p $PORT"
  echo "--------------------------------"
}

list_profiles() {
  echo "Existing profiles:"
  ls "$USERS_DIR" 2>/dev/null || echo "None"
}

revoke_profile() {
  list_profiles
  read -p "Profile to revoke: " PNAME
  if id "$PNAME" >/dev/null 2>&1; then
    userdel "$PNAME"
    rm -rf "$USERS_DIR/$PNAME" "$KEYS_DIR/$PNAME" "$KEYS_DIR/$PNAME.pub"
    echo "Revoked: $PNAME"
  else
    echo "Profile not found."
  fi
}

show_menu() {
  clear
  echo "$APP_NAME"
  echo "========================"
  echo "1) Create access profile"
  echo "2) List profiles"
  echo "3) Revoke profile"
  echo "4) Exit"
  echo ""
  read -p "Choose: " CH
}

main() {
  require_root
  init_dirs

  while true; do
    show_menu
    case "$CH" in
      1) create_profile; pause;;
      2) list_profiles; pause;;
      3) revoke_profile; pause;;
      4) exit 0;;
      *) echo "Invalid choice"; pause;;
    esac
  done
}

main
