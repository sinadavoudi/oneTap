export_shadowrocket() {
  SERVER=$(get_ip)
  echo "Server: $SERVER"
  echo "Port: 22"
  echo "Type: SSH"
}

export_ssh_link() {
  SERVER=$(get_ip)
  echo "ssh://$1@$SERVER:22"
}
