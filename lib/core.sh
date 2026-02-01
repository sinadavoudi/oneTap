APP_NAME="oneTap"
APP_VERSION="v2.0.0"

require_root() {
  [[ $EUID -ne 0 ]] && echo "Run as root" && exit 1
}

pause() {
  read -p "Press Enter to continue..."
}

get_ip() {
  curl -s ipv4.icanhazip.com || hostname -I | awk '{print $1}'
}
