select_transport() {
  echo "Choose connection mode:"
  echo "1) Fast (SSH over WebSocket)"
  echo "2) Simple (Plain SSH)"
  echo "3) Advanced (WS + TLS)"
  read -p "Choice [1-3]: " TRANSPORT_MODE
}

select_address() {
  echo "Connection address:"
  echo "1) Use server IP"
  echo "2) Use domain"
  read -p "Choice [1-2]: " ADDRESS_MODE

  if [[ $ADDRESS_MODE == "2" ]]; then
    read -p "Enter domain: " DOMAIN
  fi
}
