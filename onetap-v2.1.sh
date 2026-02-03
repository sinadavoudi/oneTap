#!/bin/bash

# oneTap v2.1 - Enhanced with Manual/Auto Configuration
# Now with customizable SNI, ports, and paths

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Banner
clear
echo -e "${BLUE}"
cat << "EOF"
   ___             _____
  / _ \ _ __   ___/__   \__ _ _ __
 | | | | '_ \ / _ \ / /\/ _` | '_ \
 | |_| | | | |  __// / | (_| | |_) |
  \___/|_| |_|\___/\/   \__,_| .__/
                             |_|
         v2.1 Enhanced Edition
EOF
echo -e "${NC}"
echo -e "${GREEN}Simple VPS to Proxy - Now with Manual/Auto Config${NC}\n"

# Check root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root: sudo su${NC}"
    exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ "$ID" != "ubuntu" ] && [ "$ID" != "debian" ]; then
        echo -e "${RED}Only Ubuntu/Debian supported${NC}"
        exit 1
    fi
fi

# Get IPv4
get_ip() {
    local ip=""
    ip=$(curl -4 -s --max-time 5 ifconfig.me 2>/dev/null)
    if [[ ! $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        ip=$(curl -4 -s --max-time 5 icanhazip.com 2>/dev/null)
    fi
    if [[ ! $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    fi
    echo "$ip"
}

# Random SNI list for auto mode (Iranian hosts first - EXPANDED)
get_random_sni() {
    local snis=(
        # Iranian Popular Sites (High Priority)
        "www.speedtest.net"
        "www.cloudflare.com"
        "zula.ir"
        "www.digikala.com"
        "www.snapp.ir"
        "www.aparat.com"
        "www.isna.ir"
        "www.irancell.ir"
        "www.mci.ir"
        "www.shatel.ir"
        "www.mokhaberat.ir"
        # Iranian Banks & Services
        "www.sep.ir"
        "www.shaparak.ir"
        "www.enamad.ir"
        "www.yjc.ir"
        "www.tasnimnews.com"
        "www.farsnews.ir"
        "www.mehrnews.com"
        # Iranian E-commerce & Apps
        "www.divar.ir"
        "www.torob.com"
        "www.bamilo.com"
        "www.fidibo.com"
        "www.taaghche.com"
        # Iranian Entertainment
        "www.filimo.com"
        "www.namava.ir"
        "www.telewebion.com"
        "www.varzesh3.com"
        "www.khabaronline.ir"
        # Iranian Tech & CDN
        "cdn.tabnak.ir"
        "static.cdn.asset.ir"
        "cdn.yjc.ir"
        # International (Fallback)
        "www.microsoft.com"
        "www.apple.com"
        "www.amazon.com"
        "www.cisco.com"
        "www.oracle.com"
        "update.microsoft.com"
        "dl.google.com"
    )
    echo "${snis[$RANDOM % ${#snis[@]}]}"
}

# Random path for WebSocket (EXPANDED)
get_random_path() {
    local paths=(
        "/ws"
        "/api"
        "/v2ray"
        "/vless"
        "/graphql"
        "/socket.io"
        "/download"
        "/update"
        "/stream"
        "/media"
        "/assets"
        "/cdn-cgi"
        "/ajax"
        "/connect"
        "/tunnel"
        "/proxy"
        "/data"
        "/api/v1"
        "/api/v2"
        "/websocket"
    )
    echo "${paths[$RANDOM % ${#paths[@]}]}"
}

# Install dependencies
install_deps() {
    echo -e "${YELLOW}Installing dependencies...${NC}"
    apt-get update -qq >/dev/null 2>&1
    apt-get install -y curl wget qrencode ufw lsof dnsutils unzip git >/dev/null 2>&1
    echo -e "${GREEN}✓ Dependencies installed${NC}"
}

# Install Xray
install_xray() {
    if [ -f /usr/local/bin/xray ]; then
        echo -e "${GREEN}✓ Xray already installed${NC}"
        return 0
    fi

    echo -e "${YELLOW}Installing Xray-core...${NC}"
    bash <(curl -sL https://github.com/XTLS/Xray-install/raw/main/install-release.sh) install >/dev/null 2>&1
    echo -e "${GREEN}✓ Xray installed${NC}"
}

# Install Caddy
install_caddy() {
    if command -v caddy >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Caddy already installed${NC}"
        return 0
    fi

    echo -e "${YELLOW}Installing Caddy...${NC}"
    apt install -y debian-keyring debian-archive-keyring apt-transport-https >/dev/null 2>&1
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' 2>/dev/null | \
        gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg 2>/dev/null
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' 2>/dev/null | \
        tee /etc/apt/sources.list.d/caddy-stable.list >/dev/null
    apt update -qq >/dev/null 2>&1
    apt install caddy -y >/dev/null 2>&1
    echo -e "${GREEN}✓ Caddy installed${NC}"
}

# Install DNSTT
install_dnstt() {
    if [ -f /usr/local/bin/dnstt-server ]; then
        echo -e "${GREEN}✓ DNSTT already installed${NC}"
        return 0
    fi

    echo -e "${YELLOW}Installing DNSTT...${NC}"
    cd /tmp
    wget -q https://github.com/farhadsaket/dnstt/releases/download/v1.20230712.0/dnstt-20230712.0-linux-amd64.tar.gz
    if [ ! -f dnstt-20230712.0-linux-amd64.tar.gz ]; then
        echo -e "${RED}✗ Failed to download DNSTT${NC}"
        return 1
    fi
    tar -xzf dnstt-20230712.0-linux-amd64.tar.gz
    mv dnstt-server /usr/local/bin/
    chmod +x /usr/local/bin/dnstt-server
    rm -f dnstt-20230712.0-linux-amd64.tar.gz
    echo -e "${GREEN}✓ DNSTT installed${NC}"
}

# Install PingTunnel
install_pingtunnel() {
    if systemctl is-active --quiet pingtunnel 2>/dev/null; then
        echo -e "${GREEN}✓ PingTunnel already installed and running${NC}"
        return 0
    fi

    echo -e "${YELLOW}Installing PingTunnel using official installer...${NC}"

    cd /tmp
    curl -fsSL https://raw.githubusercontent.com/HexaSoftwareDev/PingTunnel-Server/main/installer.sh -o installer.sh

    if [ ! -f installer.sh ]; then
        echo -e "${RED}✗ Failed to download installer${NC}"
        return 1
    fi

    # Run the installer (it handles everything automatically)
    bash installer.sh

    rm -f installer.sh

    echo -e "${GREEN}✓ PingTunnel installed${NC}"
}

# Clear port
clear_port() {
    local port=$1
    systemctl stop nginx 2>/dev/null || true
    systemctl stop apache2 2>/dev/null || true
    systemctl stop caddy 2>/dev/null || true
    systemctl stop xray 2>/dev/null || true
    sleep 1

    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        lsof -Pi :$port -sTCP:LISTEN -t | xargs kill -9 2>/dev/null || true
        sleep 1
    fi
}

# Ask for configuration mode
ask_config_mode() {
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${YELLOW}Configuration Mode:${NC}\n"
    echo -e "  ${GREEN}1) Auto Mode${NC} ${BLUE}(Recommended)${NC}"
    echo -e "     - Random SNI, port, and paths"
    echo -e "     - Optimized for Iran"
    echo -e "     - Quick setup\n"
    echo -e "  ${GREEN}2) Manual Mode${NC} ${YELLOW}(Advanced)${NC}"
    echo -e "     - Customize SNI, port, paths"
    echo -e "     - Full control"
    echo -e "     - For experienced users\n"
    echo -e "${BLUE}═══════════════════════════════════════${NC}\n"

    read -p "Choose mode (1=Auto / 2=Manual): " mode
    echo "$mode"
}

# Setup Reality (Option 1) - NOW WITH WEBSOCKET
setup_reality() {
    local ip=$1
    local regenerate=${2:-false}

    if [ "$regenerate" = false ]; then
        echo -e "\n${YELLOW}═══ Setting up Quick Setup (WebSocket) ═══${NC}\n"

        # Ask for config mode only on first setup
        CONFIG_MODE=$(ask_config_mode)
    fi

    # Generate UUID (new each time)
    UUID=$(cat /proc/sys/kernel/random/uuid)
    echo -e "UUID: ${GREEN}$UUID${NC}"

    # Configure based on mode
    if [ "$CONFIG_MODE" = "2" ] && [ "$regenerate" = false ]; then
        # Manual mode
        echo -e "\n${YELLOW}Manual Configuration:${NC}"

        read -p "Enter SNI/Host (e.g., www.digikala.com) [default: www.speedtest.net]: " CUSTOM_SNI
        SNI=${CUSTOM_SNI:-www.speedtest.net}

        read -p "Enter port [default: 443]: " CUSTOM_PORT
        PORT=${CUSTOM_PORT:-443}

        read -p "Enter WebSocket path [default: /ws]: " CUSTOM_PATH
        WS_PATH=${CUSTOM_PATH:-/ws}

    else
        # Auto mode - Random Iranian host and path
        SNI=$(get_random_sni)
        PORT=443
        WS_PATH=$(get_random_path)
    fi

    echo -e "\n${BLUE}Configuration:${NC}"
    echo "  Host/SNI: $SNI"
    echo "  Port: $PORT"
    echo "  WebSocket Path: $WS_PATH"
    echo ""

    # Clear port
    if [ "$regenerate" = false ]; then
        echo "Clearing port $PORT..."
        clear_port $PORT
    fi

    # Delete old Xray config
    echo "Cleaning old configurations..."
    rm -f /usr/local/etc/xray/config.json.old
    if [ -f /usr/local/etc/xray/config.json ]; then
        mv /usr/local/etc/xray/config.json /usr/local/etc/xray/config.json.old
    fi

    # Create NEW Xray config with WebSocket
    echo "Creating Xray configuration..."
    mkdir -p /usr/local/etc/xray
    cat > /usr/local/etc/xray/config.json << EOF
{
  "log": {"loglevel": "warning"},
  "inbounds": [{
    "listen": "0.0.0.0",
    "port": $PORT,
    "protocol": "vless",
    "settings": {
      "clients": [{"id": "$UUID"}],
      "decryption": "none"
    },
    "streamSettings": {
      "network": "ws",
      "wsSettings": {
        "path": "$WS_PATH",
        "headers": {
          "Host": "$SNI"
        }
      }
    }
  }],
  "outbounds": [{"protocol": "freedom"}]
}
EOF

    # Configure firewall (only on first setup)
    if [ "$regenerate" = false ]; then
        echo "Configuring firewall..."
        ufw --force enable >/dev/null 2>&1
        ufw allow 22/tcp >/dev/null 2>&1
        ufw allow $PORT/tcp >/dev/null 2>&1
        ufw reload >/dev/null 2>&1
    fi

    # Restart Xray
    echo "Restarting Xray..."
    systemctl restart xray
    sleep 3

    if ! systemctl is-active --quiet xray; then
        echo -e "${RED}✗ Xray failed to start${NC}"
        journalctl -u xray -n 15 --no-pager

        # Restore old config if exists
        if [ -f /usr/local/etc/xray/config.json.old ]; then
            echo "Restoring previous configuration..."
            mv /usr/local/etc/xray/config.json.old /usr/local/etc/xray/config.json
            systemctl restart xray
        fi
        return 1
    fi

    echo -e "${GREEN}✓ Xray is running${NC}"

    # Clean up old backup
    rm -f /usr/local/etc/xray/config.json.old

    # URL encode the path
    ENCODED_PATH=$(echo -n "$WS_PATH" | jq -sRr @uri)

    # Generate config link - WebSocket version
    CONFIG="vless://$UUID@$ip:$PORT?encryption=none&security=none&type=ws&host=$SNI&path=$ENCODED_PATH#oneTap-Quick"

    # Save config
    cat > /root/onetap-config.txt << EOF
╔══════════════════════════════════════╗
║   oneTap - Quick Setup (WebSocket)   ║
╚══════════════════════════════════════╝

Server IP: $ip
Port: $PORT
UUID: $UUID
Protocol: VLESS + WebSocket
Host/SNI: $SNI
Path: $WS_PATH
Config Mode: $([ "$CONFIG_MODE" = "2" ] && echo "Manual" || echo "Auto")

═══════════════════════════════════════

CONNECTION LINK (copy this):
$CONFIG

═══════════════════════════════════════
EOF

    # Display
    clear
    echo -e "${GREEN}╔══════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║      ✓ SETUP COMPLETE!              ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════╝${NC}\n"

    cat /root/onetap-config.txt

    echo -e "\n${YELLOW}QR CODE (scan with phone):${NC}"
    if command -v qrencode >/dev/null 2>&1; then
        echo "$CONFIG" | qrencode -t ANSIUTF8
    else
        echo "(qrencode not installed)"
    fi

    echo -e "\n${YELLOW}APPS:${NC}"
    echo "  Android: v2rayNG or MahsaNG"
    echo "  iOS: Streisand or Shadowrocket"
    echo "  Windows: v2rayN"

    echo -e "\n${GREEN}✓ Config saved to: /root/onetap-config.txt${NC}"

    # Regenerate option
    echo -e "\n${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${YELLOW}Options:${NC}"
    echo "  1) Test this config"
    echo "  2) Regenerate (new host + path)"
    echo "  3) Back to main menu"
    echo -e "${BLUE}═══════════════════════════════════════${NC}\n"

    read -p "Choose [1-3]: " regen_choice

    case $regen_choice in
        1)
            echo -e "\n${GREEN}Test the config in your app!${NC}"
            echo "If it doesn't work, come back and choose option 2."
            echo ""
            read -p "Press Enter when ready to continue..."
            setup_reality "$ip" false
            ;;
        2)
            echo -e "\n${YELLOW}Regenerating with new random host + path...${NC}\n"
            sleep 1
            setup_reality "$ip" true
            ;;
        3)
            return 0
            ;;
        *)
            return 0
            ;;
    esac
}

# Setup Premium (Option 2) with Auto/Manual
setup_premium() {
    local domain=$1
    local ip=$2

    echo -e "\n${YELLOW}═══ Setting up Premium (WS+TLS) ═══${NC}\n"

    # Ask for config mode
    CONFIG_MODE=$(ask_config_mode)

    # Generate UUID
    UUID=$(cat /proc/sys/kernel/random/uuid)
    echo -e "UUID: ${GREEN}$UUID${NC}"

    # Configure based on mode
    if [ "$CONFIG_MODE" = "2" ]; then
        # Manual mode
        echo -e "\n${YELLOW}Manual Configuration:${NC}"

        read -p "Enter WebSocket path [default: /ws]: " CUSTOM_PATH
        WS_PATH=${CUSTOM_PATH:-/ws}

        read -p "Enter port [default: 443]: " CUSTOM_PORT
        PORT=${CUSTOM_PORT:-443}

        read -p "Enter host header [default: $domain]: " CUSTOM_HOST
        WS_HOST=${CUSTOM_HOST:-$domain}

    else
        # Auto mode
        echo -e "\n${GREEN}Auto Mode - Using optimized settings${NC}"
        WS_PATH=$(get_random_path)
        PORT=443
        WS_HOST=$domain
    fi

    echo -e "\n${BLUE}Configuration:${NC}"
    echo "  Domain: $domain"
    echo "  Port: $PORT"
    echo "  Path: $WS_PATH"
    echo "  Host: $WS_HOST"
    echo ""

    # Test DNS
    echo "Testing DNS..."
    RESOLVED=$(dig +short "$domain" @8.8.8.8 | tail -n1)
    if [ -z "$RESOLVED" ]; then
        echo -e "${RED}⚠ Cannot resolve domain${NC}"
    elif [ "$RESOLVED" != "$ip" ]; then
        echo -e "${YELLOW}⚠ Domain resolves to $RESOLVED, server is $ip${NC}"
    else
        echo -e "${GREEN}✓ DNS correct${NC}"
    fi

    # Clear ports
    echo "Clearing ports 80 and $PORT..."
    clear_port 80
    clear_port $PORT

    # Create Xray config
    echo "Creating Xray configuration..."
    mkdir -p /usr/local/etc/xray
    cat > /usr/local/etc/xray/config.json << EOF
{
  "log": {"loglevel": "warning"},
  "inbounds": [{
    "listen": "127.0.0.1",
    "port": 10000,
    "protocol": "vless",
    "settings": {
      "clients": [{"id": "$UUID"}],
      "decryption": "none"
    },
    "streamSettings": {
      "network": "ws",
      "wsSettings": {
        "path": "$WS_PATH",
        "headers": {
          "Host": "$WS_HOST"
        }
      }
    }
  }],
  "outbounds": [{"protocol": "freedom"}]
}
EOF

    # Create Caddy config
    echo "Creating Caddy configuration..."
    mkdir -p /etc/caddy
    cat > /etc/caddy/Caddyfile << EOF
$domain {
    reverse_proxy $WS_PATH 127.0.0.1:10000
    respond "OK" 200
}
EOF

    # Start Xray
    echo "Starting Xray..."
    systemctl enable xray >/dev/null 2>&1
    systemctl restart xray
    sleep 2

    if ! systemctl is-active --quiet xray; then
        echo -e "${RED}✗ Xray failed${NC}"
        journalctl -u xray -n 10 --no-pager
        return 1
    fi
    echo -e "${GREEN}✓ Xray running${NC}"

    # Start Caddy
    echo "Starting Caddy (getting SSL certificate)..."
    systemctl enable caddy >/dev/null 2>&1
    systemctl restart caddy

    echo "Waiting for SSL (30 seconds)..."
    sleep 30

    if ! systemctl is-active --quiet caddy; then
        echo -e "${RED}✗ Caddy failed${NC}"
        journalctl -u caddy -n 10 --no-pager
        return 1
    fi
    echo -e "${GREEN}✓ Caddy running with SSL${NC}"

    # Firewall
    ufw --force enable >/dev/null 2>&1
    ufw allow 22/tcp >/dev/null 2>&1
    ufw allow 80/tcp >/dev/null 2>&1
    ufw allow $PORT/tcp >/dev/null 2>&1
    ufw reload >/dev/null 2>&1

    # Generate config (URL encode path)
    ENCODED_PATH=$(echo -n "$WS_PATH" | jq -sRr @uri)
    CONFIG="vless://$UUID@$domain:$PORT?encryption=none&security=tls&type=ws&host=$WS_HOST&path=$ENCODED_PATH&sni=$domain#oneTap-Premium"

    # Save config
    cat > /root/onetap-config.txt << EOF
╔══════════════════════════════════════╗
║    oneTap - Premium Configuration    ║
╚══════════════════════════════════════╝

Domain: $domain
Port: $PORT
UUID: $UUID
Protocol: VLESS + WebSocket + TLS
Path: $WS_PATH
Host: $WS_HOST
Config Mode: $([ "$CONFIG_MODE" = "2" ] && echo "Manual" || echo "Auto")

═══════════════════════════════════════

CONNECTION LINK (copy this):
$CONFIG

═══════════════════════════════════════
EOF

    # Display
    clear
    echo -e "${GREEN}╔══════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║      ✓ INSTALLATION COMPLETE!       ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════╝${NC}\n"

    cat /root/onetap-config.txt

    echo -e "\n${YELLOW}QR CODE (scan with phone):${NC}"
    if command -v qrencode >/dev/null 2>&1; then
        echo "$CONFIG" | qrencode -t ANSIUTF8
    else
        echo "(qrencode not installed)"
    fi

    echo -e "\n${YELLOW}APPS:${NC}"
    echo "  Android: v2rayNG or MahsaNG"
    echo "  iOS: Streisand or Shadowrocket"
    echo "  Windows: v2rayN"

    echo -e "\n${GREEN}✓ Config saved to: /root/onetap-config.txt${NC}\n"
}

# Setup Advanced (Option 3) - Placeholder
setup_advanced() {
    echo -e "${YELLOW}Advanced setup with multiple protocols${NC}"
    echo -e "${RED}Coming soon...${NC}"
    echo ""
    read -p "Press Enter to continue..."
}

# Setup DNSTT (Option 4)
setup_dnstt() {
    local ip=$1

    echo -e "\n${YELLOW}═══ Setting up DNS Tunnel (DNSTT) ═══${NC}\n"

    echo -e "${BLUE}DNS Tunnel works by encapsulating traffic in DNS queries.${NC}"
    echo -e "${BLUE}This works even when other protocols are blocked.${NC}\n"

    echo -e "${YELLOW}IMPORTANT: You need a domain with NS record access${NC}"
    echo -e "Your domain registrar must allow you to set NS records.\n"

    read -p "Enter your domain (e.g., example.com): " DOMAIN

    if [ -z "$DOMAIN" ]; then
        echo -e "${RED}Domain is required!${NC}"
        return 1
    fi

    echo -e "\n${YELLOW}Your server IP: $ip${NC}"
    echo -e "\n${YELLOW}DNS SETUP REQUIRED:${NC}"
    echo "You need to add these DNS records at your domain registrar:"
    echo ""
    echo "  1. A record:"
    echo "     Name: ns1.$DOMAIN"
    echo "     Value: $ip"
    echo ""
    echo "  2. NS record:"
    echo "     Name: $DOMAIN (or subdomain)"
    echo "     Value: ns1.$DOMAIN"
    echo ""

    read -p "Have you added these DNS records? (y/n): " dns_ready

    if [ "$dns_ready" != "y" ]; then
        echo -e "\n${YELLOW}Please add the DNS records first, then run this script again.${NC}\n"
        return 1
    fi

    echo -e "\n${YELLOW}Installing DNSTT...${NC}"
    if ! install_dnstt; then
        echo -e "${RED}Failed to install DNSTT${NC}"
        return 1
    fi

    # Generate key
    DNSTT_KEY=$(openssl rand -hex 32)

    echo "Creating DNSTT service..."

    # Create systemd service
    cat > /etc/systemd/system/dnstt.service << EOF
[Unit]
Description=DNSTT Server
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/dnstt-server -udp :53 -privkey $DNSTT_KEY $DOMAIN 127.0.0.1:8080
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    # Configure firewall
    echo "Configuring firewall..."
    ufw allow 53/udp >/dev/null 2>&1
    ufw reload >/dev/null 2>&1

    # Start service
    echo "Starting DNSTT service..."
    systemctl daemon-reload
    systemctl enable dnstt >/dev/null 2>&1
    systemctl restart dnstt

    sleep 2

    if ! systemctl is-active --quiet dnstt; then
        echo -e "${RED}✗ DNSTT failed to start${NC}"
        journalctl -u dnstt -n 15 --no-pager
        return 1
    fi

    echo -e "${GREEN}✓ DNSTT is running${NC}"

    # Save config
    cat > /root/onetap-config.txt << EOF
╔══════════════════════════════════════╗
║    oneTap - DNS Tunnel Config        ║
╚══════════════════════════════════════╝

Domain: $DOMAIN
Server IP: $ip
Port: 53 (UDP)
Protocol: DNSTT
Private Key: $DNSTT_KEY

═══════════════════════════════════════

DNS RECORDS NEEDED:
1. A Record: ns1.$DOMAIN → $ip
2. NS Record: $DOMAIN → ns1.$DOMAIN

═══════════════════════════════════════

CLIENT SETUP:

1. Download DNSTT client:
   https://github.com/farhadsaket/dnstt/releases

2. Run client:

   dnstt-client -doh https://dns.google/dns-query \\
                -pubkey $DNSTT_KEY \\
                $DOMAIN 127.0.0.1:1080

3. Use SOCKS5 proxy: 127.0.0.1:1080

═══════════════════════════════════════
EOF

    # Display
    clear
    echo -e "${GREEN}╔══════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║      ✓ DNSTT SETUP COMPLETE!        ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════╝${NC}\n"

    cat /root/onetap-config.txt

    echo -e "\n${GREEN}✓ Config saved to: /root/onetap-config.txt${NC}\n"
}

# Setup PingTunnel (Option 5 - ICMP)
setup_pingtunnel() {
    local ip=$1

    echo -e "\n${YELLOW}═══ Setting up Ping Tunnel (ICMP) ═══${NC}\n"

    echo -e "${BLUE}Ping Tunnel uses ICMP (ping) protocol to tunnel traffic.${NC}"
    echo -e "${BLUE}This works even when TCP/UDP protocols are blocked!${NC}\n"

    echo -e "${YELLOW}How it works:${NC}"
    echo "  • Uses ICMP Echo Request/Reply (ping packets)"
    echo "  • Bypasses firewalls that allow ping"
    echo "  • Works when all other methods fail"
    echo "  • No domain or DNS setup needed"
    echo ""

    read -p "Continue with PingTunnel setup? (y/n): " confirm

    if [ "$confirm" != "y" ]; then
        return 1
    fi

    echo -e "\n${YELLOW}Installing PingTunnel...${NC}"
    echo "This will run the official installer from HexaSoftwareDev"
    echo ""

    # The installer does everything automatically!
    if ! install_pingtunnel; then
        echo -e "${RED}Failed to install PingTunnel${NC}"
        return 1
    fi

    # Wait for service to start
    sleep 3

    # Get the port from the running service
    PT_PORT=$(systemctl show pingtunnel -p ExecStart | grep -oP '\d{4,5}' | tail -1)
    if [ -z "$PT_PORT" ]; then
        PT_PORT="9090" # Default port
    fi

    if systemctl is-active --quiet pingtunnel; then
        echo -e "${GREEN}✓ PingTunnel is running on port $PT_PORT${NC}"
    else
        echo -e "${RED}✗ PingTunnel failed to start${NC}"
        journalctl -u pingtunnel -n 15 --no-pager
        return 1
    fi

    # Save config
    cat > /root/onetap-config.txt << EOF
╔══════════════════════════════════════╗
║   oneTap - Ping Tunnel (ICMP) Config ║
╚══════════════════════════════════════╝

Server IP: $ip
Server Port: $PT_PORT (auto-configured)
Protocol: ICMP (Ping)

═══════════════════════════════════════

CLIENT SETUP:

1. Download PingTunnel client:
   https://github.com/HexaSoftwareDev/PingTunnel-Client/releases

2. Run the client (one command):

   Windows:
   pingtunnel-client.exe $ip $PT_PORT

   Linux:
   ./pingtunnel-client $ip $PT_PORT

   Mac:
   ./pingtunnel-client $ip $PT_PORT

3. Client will create SOCKS5 proxy on:
   127.0.0.1:1080

4. Configure your apps to use SOCKS5:
   Host: 127.0.0.1
   Port: 1080

═══════════════════════════════════════

WHEN TO USE ICMP TUNNEL:
✓ All TCP/UDP ports are blocked
✓ Only ping (ICMP) is allowed
✓ Extreme filtering situations
✓ As emergency backup method

ADVANTAGES:
✓ Uses ICMP (ping) - rarely blocked
✓ Simple one-command setup
✓ Works through most firewalls
✓ No password/key needed
✓ Auto-configured by installer

DISADVANTAGES:
✗ Slower than other methods
✗ May have packet loss
✗ Some networks block ICMP too

═══════════════════════════════════════

TESTING:
1. Test if ping works from your location:
   ping $ip

2. If ping responds, the tunnel will work!

3. Server is running automatically on port $PT_PORT

═══════════════════════════════════════

MANAGEMENT:
• Check status: systemctl status pingtunnel
• View logs: journalctl -u pingtunnel -f
• Restart: systemctl restart pingtunnel
• Stop: systemctl stop pingtunnel

═══════════════════════════════════════
EOF

    # Display
    clear
    echo -e "${GREEN}╔══════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   ✓ PINGTUNNEL SETUP COMPLETE!      ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════╝${NC}\n"

    cat /root/onetap-config.txt

    echo -e "\n${YELLOW}QUICK TEST:${NC}"
    echo "  ping $ip"
    echo ""
    echo "If ping works, your ICMP tunnel is ready!"

    echo -e "\n${YELLOW}CLIENT DOWNLOAD:${NC}"
    echo "  https://github.com/HexaSoftwareDev/PingTunnel-Client/releases"

    echo -e "\n${YELLOW}CLIENT COMMAND:${NC}"
    echo "  pingtunnel-client $ip $PT_PORT"

    echo -e "\n${GREEN}✓ Config saved to: /root/onetap-config.txt${NC}\n"
}

# Speed optimization
optimize_speed() {
    echo -e "\n${YELLOW}═══ Speed Optimization ═══${NC}\n"

    echo "Checking BBR status..."
    if sysctl net.ipv4.tcp_congestion_control 2>/dev/null | grep -q bbr; then
        echo -e "${GREEN}✓ BBR already enabled${NC}"
    else
        echo "Enabling BBR..."
        modprobe tcp_bbr 2>/dev/null
        echo "tcp_bbr" >> /etc/modules-load.d/modules.conf
        echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
        echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
        sysctl -p >/dev/null 2>&1
        echo -e "${GREEN}✓ BBR enabled${NC}"
    fi

    echo -e "\n${GREEN}✓ Optimization complete${NC}"
    echo "Restart your VPS for full effect: reboot"
    echo ""
}

# Show configs
show_configs() {
    clear
    echo -e "${GREEN}═══ Your Configuration ═══${NC}\n"

    if [ -f /root/onetap-config.txt ]; then
        cat /root/onetap-config.txt
    else
        echo -e "${YELLOW}No configuration found${NC}"
        echo "Please run a setup first"
    fi

    echo ""
}

# Uninstall
uninstall() {
    echo -e "${RED}═══ Uninstall oneTap ═══${NC}\n"
    read -p "Are you sure? (y/n): " confirm

    if [ "$confirm" != "y" ]; then
        return
    fi

    echo "Stopping services..."
    systemctl stop xray caddy dnstt pingtunnel 2>/dev/null
    systemctl disable xray caddy dnstt pingtunnel 2>/dev/null

    echo "Removing files..."
    rm -rf /usr/local/bin/xray
    rm -rf /usr/local/etc/xray
    rm -rf /etc/systemd/system/xray*
    rm -rf /etc/caddy
    rm -rf /usr/local/bin/dnstt-server
    rm -rf /etc/systemd/system/dnstt*
    rm -rf /usr/local/bin/pingtunnel
    rm -rf /etc/systemd/system/pingtunnel*
    rm -rf /root/onetap-config.txt

    systemctl daemon-reload

    echo -e "${GREEN}✓ Uninstalled${NC}\n"
}

# Main menu
main_menu() {
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${GREEN}Choose your setup:${NC}\n"
    echo -e "  ${YELLOW}1)${NC} Quick Setup (WebSocket - No domain) ${GREEN}← Recommended${NC}"
    echo -e "  ${YELLOW}2)${NC} Premium Setup (WS+TLS - With domain)"
    echo -e "  ${YELLOW}3)${NC} Advanced Setup (Multiple protocols)"
    echo -e "  ${YELLOW}4)${NC} DNS Tunnel (DNSTT - For heavy filtering)"
    echo -e "  ${YELLOW}5)${NC} Ping Tunnel (ICMP - Works when everything blocked)"
    echo -e "  ${YELLOW}6)${NC} Speed Optimization (Enable BBR)"
    echo -e "  ${YELLOW}7)${NC} Show My Configs"
    echo -e "  ${YELLOW}8)${NC} Uninstall"
    echo -e "  ${YELLOW}0)${NC} Exit"
    echo -e "${BLUE}═══════════════════════════════════════${NC}\n"

    read -p "Enter choice [0-8]: " choice

    IP=$(get_ip)

    case $choice in
        1)
            if [ -z "$IP" ]; then
                read -p "Cannot detect IP. Enter manually: " IP
            fi
            echo -e "\n${GREEN}Server IP: $IP${NC}"
            install_deps
            install_xray
            setup_reality "$IP"
            ;;
        2)
            if [ -z "$IP" ]; then
                read -p "Cannot detect IP. Enter manually: " IP
            fi
            echo -e "\n${GREEN}Server IP: $IP${NC}"
            read -p "Enter your domain: " DOMAIN
            if [ -z "$DOMAIN" ]; then
                echo -e "${RED}Domain required${NC}"
                exit 1
            fi
            install_deps
            install_xray
            install_caddy
            setup_premium "$DOMAIN" "$IP"
            ;;
        3)
            setup_advanced
            ;;
        4)
            if [ -z "$IP" ]; then
                read -p "Cannot detect IP. Enter manually: " IP
            fi
            install_deps
            setup_dnstt "$IP"
            ;;
        5)
            if [ -z "$IP" ]; then
                read -p "Cannot detect IP. Enter manually: " IP
            fi
            install_deps
            setup_pingtunnel "$IP"
            ;;
        6)
            optimize_speed
            ;;
        7)
            show_configs
            ;;
        8)
            uninstall
            ;;
        0)
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
}

main_menu
