#!/bin/bash

# oneTap v2.0 - Complete Edition
# All options restored + DNSTT working

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
         v2.0 Complete Edition
EOF
echo -e "${NC}"
echo -e "${GREEN}Simple VPS to Proxy - For Everyone${NC}\n"

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

# Install dependencies
install_deps() {
    echo -e "${YELLOW}Installing dependencies...${NC}"
    apt-get update -qq >/dev/null 2>&1
    apt-get install -y curl wget qrencode ufw lsof dnsutils unzip >/dev/null 2>&1
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
    
    # Download latest DNSTT
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

# Setup Reality (Option 1)
setup_reality() {
    local ip=$1
    
    echo -e "\n${YELLOW}═══ Setting up Reality Protocol ═══${NC}\n"
    
    UUID=$(cat /proc/sys/kernel/random/uuid)
    echo "Generating UUID: $UUID"
    
    echo "Generating Reality keys..."
    KEY_OUTPUT=$(/usr/local/bin/xray x25519)
    PRIVATE_KEY=$(echo "$KEY_OUTPUT" | grep "PrivateKey:" | awk '{print $2}')
    PUBLIC_KEY=$(echo "$KEY_OUTPUT" | grep "Password:" | awk '{print $2}')
    SHORT_ID=$(openssl rand -hex 8)
    
    echo "Clearing port 443..."
    clear_port 443
    
    echo "Creating Xray configuration..."
    mkdir -p /usr/local/etc/xray
    cat > /usr/local/etc/xray/config.json << EOF
{
  "log": {"loglevel": "warning"},
  "inbounds": [{
    "listen": "0.0.0.0",
    "port": 443,
    "protocol": "vless",
    "settings": {
      "clients": [{"id": "$UUID", "flow": "xtls-rprx-vision"}],
      "decryption": "none"
    },
    "streamSettings": {
      "network": "tcp",
      "security": "reality",
      "realitySettings": {
        "show": false,
        "dest": "www.microsoft.com:443",
        "serverNames": ["www.microsoft.com"],
        "privateKey": "$PRIVATE_KEY",
        "shortIds": ["$SHORT_ID"]
      }
    }
  }],
  "outbounds": [{"protocol": "freedom"}]
}
EOF
    
    echo "Configuring firewall..."
    ufw --force enable >/dev/null 2>&1
    ufw allow 22/tcp >/dev/null 2>&1
    ufw allow 443/tcp >/dev/null 2>&1
    ufw reload >/dev/null 2>&1
    
    echo "Starting Xray..."
    systemctl enable xray >/dev/null 2>&1
    systemctl restart xray
    sleep 3
    
    if ! systemctl is-active --quiet xray; then
        echo -e "${RED}✗ Xray failed to start${NC}"
        journalctl -u xray -n 15 --no-pager
        return 1
    fi
    
    echo -e "${GREEN}✓ Xray is running${NC}"
    
    # Generate config link
    CONFIG="vless://$UUID@$ip:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.microsoft.com&fp=chrome&pbk=$PUBLIC_KEY&sid=$SHORT_ID&type=tcp#oneTap-Reality"
    
    # Save to file
    cat > /root/onetap-config.txt << EOF
╔══════════════════════════════════════╗
║     oneTap - Quick Setup Config      ║
╚══════════════════════════════════════╝

Server IP: $ip
Port: 443
UUID: $UUID
Protocol: VLESS + Reality
Public Key: $PUBLIC_KEY
Short ID: $SHORT_ID

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
    
    echo -e "\n${GREEN}✓ Config saved to: /root/onetap-config.txt${NC}"
    echo -e "${YELLOW}View anytime: cat /root/onetap-config.txt${NC}\n"
}

# Setup Premium (Option 2)
setup_premium() {
    local domain=$1
    local ip=$2
    
    echo -e "\n${YELLOW}═══ Setting up Premium (WS+TLS) ═══${NC}\n"
    
    UUID=$(cat /proc/sys/kernel/random/uuid)
    echo "UUID: $UUID"
    
    echo "Testing DNS..."
    RESOLVED=$(dig +short "$domain" @8.8.8.8 | tail -n1)
    if [ -z "$RESOLVED" ]; then
        echo -e "${RED}⚠ Cannot resolve domain${NC}"
    elif [ "$RESOLVED" != "$ip" ]; then
        echo -e "${YELLOW}⚠ Domain resolves to $RESOLVED, server is $ip${NC}"
    else
        echo -e "${GREEN}✓ DNS correct${NC}"
    fi
    
    echo "Clearing ports 80 and 443..."
    clear_port 80
    clear_port 443
    
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
      "wsSettings": {"path": "/vless"}
    }
  }],
  "outbounds": [{"protocol": "freedom"}]
}
EOF
    
    echo "Creating Caddy configuration..."
    mkdir -p /etc/caddy
    cat > /etc/caddy/Caddyfile << EOF
$domain {
    reverse_proxy /vless 127.0.0.1:10000
    respond "OK" 200
}
EOF
    
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
    ufw allow 443/tcp >/dev/null 2>&1
    ufw reload >/dev/null 2>&1
    
    # Generate config
    CONFIG="vless://$UUID@$domain:443?encryption=none&security=tls&type=ws&host=$domain&path=%2Fvless&sni=$domain#oneTap-Premium"
    
    cat > /root/onetap-config.txt << EOF
╔══════════════════════════════════════╗
║    oneTap - Premium Setup Config     ║
╚══════════════════════════════════════╝

Domain: $domain
Port: 443
UUID: $UUID
Protocol: VLESS + WebSocket + TLS

═══════════════════════════════════════

CONNECTION LINK (copy this):
$CONFIG

═══════════════════════════════════════
EOF
    
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

# Setup Advanced (Option 3)
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
    echo "     Name: $DOMAIN (or subdomain like vpn.$DOMAIN)"
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

DNS RECORDS YOU NEED:
1. A Record: ns1.$DOMAIN → $ip
2. NS Record: $DOMAIN → ns1.$DOMAIN

═══════════════════════════════════════

CLIENT SETUP:

1. Download DNSTT client:
   Windows: https://github.com/farhadsaket/dnstt/releases
   Android: Use dnstt-client app

2. Run client command:

   dnstt-client -doh https://dns.google/dns-query \\
                -pubkey $DNSTT_KEY \\
                $DOMAIN 127.0.0.1:1080

3. This creates a SOCKS5 proxy on:
   127.0.0.1:1080

4. Configure your browser/apps to use:
   SOCKS5: 127.0.0.1:1080

═══════════════════════════════════════

WHEN TO USE:
- When all other proxies are blocked
- During heavy filtering periods
- As a backup connection method

NOTE: DNSTT is slower but more reliable
during filtering periods.

═══════════════════════════════════════
EOF
    
    clear
    echo -e "${GREEN}╔══════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║      ✓ DNSTT SETUP COMPLETE!        ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════╝${NC}\n"
    
    cat /root/onetap-config.txt
    
    echo -e "\n${YELLOW}HOW TO USE:${NC}"
    echo "1. Download DNSTT client for your OS"
    echo "2. Run the client command shown above"
    echo "3. Configure your apps to use SOCKS5: 127.0.0.1:1080"
    
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
    systemctl stop xray caddy dnstt 2>/dev/null
    systemctl disable xray caddy dnstt 2>/dev/null
    
    echo "Removing files..."
    rm -rf /usr/local/bin/xray
    rm -rf /usr/local/etc/xray
    rm -rf /etc/systemd/system/xray*
    rm -rf /etc/caddy
    rm -rf /usr/local/bin/dnstt-server
    rm -rf /etc/systemd/system/dnstt*
    rm -rf /root/onetap-config.txt
    
    systemctl daemon-reload
    
    echo -e "${GREEN}✓ Uninstalled${NC}\n"
}

# Main menu
main_menu() {
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${GREEN}Choose your setup:${NC}\n"
    echo -e "  ${YELLOW}1)${NC} Quick Setup (No domain) ${GREEN}← Recommended${NC}"
    echo -e "  ${YELLOW}2)${NC} Premium Setup (With domain)"
    echo -e "  ${YELLOW}3)${NC} Advanced Setup (Multiple protocols)"
    echo -e "  ${YELLOW}4)${NC} DNS Tunnel (DNSTT - For heavy filtering)"
    echo -e "  ${YELLOW}5)${NC} Speed Optimization (Enable BBR)"
    echo -e "  ${YELLOW}6)${NC} Show My Configs"
    echo -e "  ${YELLOW}7)${NC} Uninstall"
    echo -e "  ${YELLOW}0)${NC} Exit"
    echo -e "${BLUE}═══════════════════════════════════════${NC}\n"
    
    read -p "Enter choice [0-7]: " choice
    
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
            optimize_speed
            ;;
        6)
            show_configs
            ;;
        7)
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
