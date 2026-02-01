#!/usr/bin/env bash
source lib/core.sh
source lib/prompt.sh
source lib/users.sh
source lib/ssh.sh
source lib/transport.sh
source lib/export.sh

require_root

select_transport
select_address
optimize_ssh
setup_transport

while true; do
  clear
  echo "$APP_NAME $APP_VERSION"
  echo "1) Create user"
  echo "2) Delete user"
  echo "3) List users"
  echo "4) Show connection info"
  echo "0) Exit"
  read -p "> " C

  case $C in
    1) create_user; pause ;;
    2) delete_user; pause ;;
    3) list_users; pause ;;
    4)
       read -p "Username: " U
       export_shadowrocket
       export_ssh_link "$U"
       pause ;;
    0) exit ;;
  esac
done
