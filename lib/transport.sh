setup_transport() {
  case "$TRANSPORT_MODE" in
    1)
      echo "Setting up SSH over WebSocket (placeholder)"
      ;;
    2)
      echo "Using plain SSH"
      ;;
    3)
      echo "Setting up WS + TLS (placeholder)"
      ;;
  esac
}
