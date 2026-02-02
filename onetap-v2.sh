#!/bin/bash

# oneTap v2.0 - Enhanced Edition (Fixed)
# Simple VPS to Proxy converter for everyone

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
         v2.0 Enhanced Edition
EOF
echo -e "${NC}"
echo -e "${GREEN}Simple VPS to Proxy - For Everyone${NC}\n"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root (use: sudo su)${NC}"
    exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo -e "${RED}Cannot detect OS${NC}"
    exit 1
fi

# Get server IPv4 (fix for IPv6 issue)
get_ipv4() {
    # Try multiple methods to get IPv4
    local ip=""
    
    # Method 1: ip route
    ip=$(ip -4 route get 8.8.8.8 2>/dev/null | grep -oP 'src \K\S+')
    
    # Method 2: hostname
    if [ -z "$ip" ]; then
        ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    fi
    
    # Method 3: curl services
    if [ -z "$ip" ]; then
        ip=$(curl -4 -s --max-time 5 ifconfig.me 2>/dev/null)
    fi
    
    if [ -z "$ip" ]; then
        ip=$(curl -4 -s --max-time 5 api.ipify.org 2>/dev/null)
    fi
    
    if [ -z "$ip" ]; then
        ip=$(curl -4 -s --max-time 5 icanhazip.com 2>/dev/null)
    fi
    
    # Validate IPv4
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo "$ip"
    else
        echo ""
    fi
}

# Main Menu
main_menu() {
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${GREEN}Choose your setup:${NC}\n"
    echo -e "  ${YELLOW}1)${NC} Quick Setup (No domain needed) ${GREEN}← Recommended${NC}"
    echo -e "     - Fast and simple"
    echo -e "     - Works immediately"
    echo -e "     - Best for beginners\n"
    
    echo -e "  ${YELLOW}2)${NC} Premium Setup (I have a domain)"
    echo -e "     - Better connection quality"
    echo -e "     - Auto SSL certificate"
    echo -e "     - Harder to detect\n"
    
    echo -e "  ${YELLOW}3)${NC} Advanced Setup (All protocols)"
    echo -e "     - Multiple connection methods"
    echo -e "     - Maximum compatibility"
    echo -e "     - For power users\n"
    
    echo -e "  ${YELLOW}4)${NC} DNS Tunnel (For heavy filtering)"
    echo -e "     - Works when everything else fails"
    echo -e "     - DNS-based tunnel"
    echo -e "     - Bypass deep packet inspection\n"
    
    echo -e "  ${YELLOW}5)${NC} Speed Test & Optimization"
    echo -e "  ${YELLOW}6)${NC} Show My Configs"
    echo -e "  ${YELLOW}7)${NC} Uninstall"
    echo -e "  ${YELLOW}0)${NC} Exit\n"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    
    read -p "Enter your choice [0-7]: " choice
    
    case $choice in
        1) quick_setup ;;
        2) premium_setup ;;
        3) advanced_setup ;;
        4) dns_tunnel_setup ;;
        5) optimize_speed ;;
        6) show_configs ;;
        7) uninstall ;;
        0) exit 0 ;;
        *) echo -e "${RED}Invalid option${NC}" && sleep 2 && main_menu ;;
    esac
}

# Quick Setup - No domain needed (Reality Protocol)
quick_setup() {
    clear
    echo -e "${GREEN}═══ Quick Setup (No Domain) ═══${NC}\n"
    echo -e "This will install:"
    echo -e "  ✓ Xray-core with Reality protocol"
    echo -e "  ✓ No SSL certificate needed"
    echo -e "  ✓ Works immediately"
    echo -e "  ✓ Good speed and security\n"
    
    read -p "Continue? (y/n): " confirm
    if [ "$confirm" != "y" ]; then
        main_menu
        return
    fi
    
    echo -e "\n${YELLOW}Detecting server IP...${NC}"
    SERVER_IP=$(get_ipv4)
    
    if [ -z "$SERVER_IP" ]; then
        echo -e "${RED}Could not detect server IPv4 address!${NC}"
        echo -e "${YELLOW}Please enter your server IP manually:${NC}"
        read -p "IP Address: " SERVER_IP
    else
        echo -e "${GREEN}Detected IP: $SERVER_IP${NC}"
    fi
    
    echo -e "\n${YELLOW}Installing dependencies...${NC}"
    install_dependencies
    
    echo -e "\n${YELLOW}Installing Xray-core...${NC}"
    install_xray
    
    echo -e "\n${YELLOW}Configuring Reality protocol...${NC}"
    setup_reality "$SERVER_IP"
    
    echo -e "\n${YELLOW}Configuring firewall...${NC}"
    configure_firewall
    
    echo -e "\n${GREEN}✓ Installation complete!${NC}\n"
    show_quick_config
    
    read -p "Press Enter to return to menu..."
    main_menu
}

# Premium Setup - With domain
premium_setup() {
    clear
    echo -e "${GREEN}═══ Premium Setup (With Domain) ═══${NC}\n"
    echo -e "This will install:"
    echo -e "  ✓ Xray-core with VLESS + WebSocket"
    echo -e "  ✓ Auto SSL certificate (Let's Encrypt)"
    echo -e "  ✓ Better disguise as normal website"
    echo -e "  ✓ Harder to detect and block\n"
    
    echo -e "${YELLOW}Requirements:${NC}"
    echo -e "  • A domain name (e.g., example.com)"
    echo -e "  • Domain DNS pointed to this server IP"
    echo -e "  • Port 80 and 443 must be open\n"
    
    SERVER_IP=$(get_ipv4)
    echo -e "${GREEN}Your server IP: $SERVER_IP${NC}"
    echo -e "${YELLOW}Make sure your domain points to this IP!${NC}\n"
    
    read -p "Do you have a domain ready? (y/n): " has_domain
    if [ "$has_domain" != "y" ]; then
        echo -e "\n${YELLOW}Please:"
        echo -e "  1. Get a free domain from: freenom.com or afraid.org"
        echo -e "  2. Point domain to this IP: $SERVER_IP"
        echo -e "  3. Wait 5-10 minutes for DNS propagation"
        echo -e "  4. Run this script again${NC}\n"
        read -p "Press Enter to return to menu..."
        main_menu
        return
    fi
    
    read -p "Enter your domain (e.g., vpn.example.com): " DOMAIN
    
    # Test DNS resolution
    echo -e "\n${YELLOW}Testing DNS resolution...${NC}"
    RESOLVED_IP=$(dig +short "$DOMAIN" @8.8.8.8 | tail -n1)
    
    if [ -z "$RESOLVED_IP" ]; then
        echo -e "${RED}Warning: Cannot resolve domain!${NC}"
        echo -e "${YELLOW}DNS might not be configured properly.${NC}"
        read -p "Continue anyway? (y/n): " continue_anyway
        if [ "$continue_anyway" != "y" ]; then
            main_menu
            return
        fi
    elif [ "$RESOLVED_IP" != "$SERVER_IP" ]; then
        echo -e "${RED}Warning: Domain resolves to $RESOLVED_IP but server IP is $SERVER_IP${NC}"
        read -p "Continue anyway? (y/n): " continue_anyway
        if [ "$continue_anyway" != "y" ]; then
            main_menu
            return
        fi
    else
        echo -e "${GREEN}✓ DNS is correctly configured${NC}"
    fi
    
    echo -e "\n${YELLOW}Installing dependencies...${NC}"
    install_dependencies
    
    echo -e "\n${YELLOW}Installing Xray-core...${NC}"
    install_xray
    
    echo -e "\n${YELLOW}Installing Caddy (for auto SSL)...${NC}"
    install_caddy
    
    echo -e "\n${YELLOW}Configuring VLESS + WebSocket + TLS...${NC}"
    setup_vless_ws_tls "$DOMAIN"
    
    echo -e "\n${YELLOW}Configuring firewall...${NC}"
    configure_firewall
    
    echo -e "\n${GREEN}✓ Installation complete!${NC}\n"
    show_premium_config "$DOMAIN"
    
    read -p "Press Enter to return to menu..."
    main_menu
}

# Advanced Setup - All protocols
advanced_setup() {
    clear
    echo -e "${GREEN}═══ Advanced Setup (All Protocols) ═══${NC}\n"
    echo -e "This will install:"
    echo -e "  ✓ VLESS (optimized)"
    echo -e "  ✓ Trojan"
    echo -e "  ✓ Shadowsocks"
    echo -e "  ✓ Multiple ports"
    echo -e "  ✓ Subscription link\n"
    
    read -p "Continue? (y/n): " confirm
    if [ "$confirm" != "y" ]; then
        main_menu
        return
    fi
    
    read -p "Do you have a domain? (y/n): " has_domain_adv
    
    SERVER_IP=$(get_ipv4)
    echo -e "${GREEN}Server IP: $SERVER_IP${NC}\n"
    
    echo -e "${YELLOW}Installing dependencies...${NC}"
    install_dependencies
    
    echo -e "${YELLOW}Installing Xray-core...${NC}"
    install_xray
    
    if [ "$has_domain_adv" = "y" ]; then
        read -p "Enter your domain: " DOMAIN_ADV
        
        # Test DNS
        RESOLVED_IP=$(dig +short "$DOMAIN_ADV" @8.8.8.8 | tail -n1)
        if [ -z "$RESOLVED_IP" ] || [ "$RESOLVED_IP" != "$SERVER_IP" ]; then
            echo -e "${RED}Warning: DNS might not be configured properly${NC}"
        fi
        
        echo -e "\n${YELLOW}Installing Caddy...${NC}"
        install_caddy
        setup_multi_protocol_domain "$DOMAIN_ADV"
    else
        setup_multi_protocol_no_domain "$SERVER_IP"
    fi
    
    echo -e "\n${YELLOW}Configuring firewall...${NC}"
    configure_firewall
    
    echo -e "\n${GREEN}✓ Installation complete!${NC}\n"
    show_advanced_config
    
    read -p "Press Enter to return to menu..."
    main_menu
}

# DNS Tunnel Setup (NEW!)
dns_tunnel_setup() {
    clear
    echo -e "${GREEN}═══ DNS Tunnel Setup ═══${NC}\n"
    echo -e "This will install:"
    echo -e "  ✓ DNSTT (DNS Tunnel)"
    echo -e "  ✓ Works over DNS protocol"
    echo -e "  ✓ Bypasses deep packet inspection"
    echo -e "  ✓ Works when other methods fail\n"
    
    echo -e "${YELLOW}Note: This requires a domain with NS records${NC}\n"
    
    read -p "Continue? (y/n): " confirm
    if [ "$confirm" != "y" ]; then
        main_menu
        return
    fi
    
    read -p "Enter your domain: " DNS_DOMAIN
    
    SERVER_IP=$(get_ipv4)
    
    echo -e "\n${YELLOW}Installing DNSTT...${NC}"
    install_dnstt
    
    echo -e "\n${YELLOW}Configuring DNS Tunnel...${NC}"
    setup_dnstt "$DNS_DOMAIN" "$SERVER_IP"
    
    echo -e "\n${GREEN}✓ Installation complete!${NC}\n"
    show_dnstt_config
    
    read -p "Press Enter to return to menu..."
    main_menu
}

# Speed Optimization
optimize_speed() {
    clear
    echo -e "${GREEN}═══ Speed Test & Optimization ═══${NC}\n"
    
    echo -e "${YELLOW}Current status:${NC}"
    echo -n "  BBR: "
    if sysctl net.ipv4.tcp_congestion_control 2>/dev/null | grep -q bbr; then
        echo -e "${GREEN}Enabled ✓${NC}"
    else
        echo -e "${RED}Disabled ✗${NC}"
    fi
    
    echo -e "\n${YELLOW}Available optimizations:${NC}"
    echo -e "  1) Enable BBR (Google's congestion control - 2-10x faster)"
    echo -e "  2) Optimize kernel parameters"
    echo -e "  3) Enable both (Recommended)"
    echo -e "  0) Back to main menu\n"
    
    read -p "Choose option: " opt_choice
    
    case $opt_choice in
        1) enable_bbr ;;
        2) optimize_kernel ;;
        3) enable_bbr && optimize_kernel ;;
        0) main_menu ;;
        *) echo -e "${RED}Invalid option${NC}" && sleep 2 && optimize_speed ;;
    esac
    
    echo -e "\n${GREEN}✓ Optimization complete!${NC}"
    echo -e "${YELLOW}Restarting services...${NC}"
    systemctl restart xray 2>/dev/null || true
    
    echo -e "${GREEN}Done!${NC}\n"
    read -p "Press Enter to return to menu..."
    main_menu
}

# Show saved configs
show_configs() {
    clear
    echo -e "${GREEN}═══ Your Saved Configurations ═══${NC}\n"
    
    if [ -f /root/onetap-config.txt ]; then
        cat /root/onetap-config.txt
    else
        echo -e "${YELLOW}No configurations found.${NC}"
        echo -e "Please run a setup first.\n"
    fi
    
    read -p "Press Enter to return to menu..."
    main_menu
}

# Uninstall
uninstall() {
    clear
    echo -e "${RED}═══ Uninstall oneTap ═══${NC}\n"
    echo -e "${YELLOW}This will remove:${NC}"
    echo -e "  • Xray-core"
    echo -e "  • Caddy (if installed)"
    echo -e "  • DNSTT (if installed)"
    echo -e "  • All configurations\n"
    
    read -p "Are you sure? (y/n): " confirm_uninstall
    if [ "$confirm_uninstall" != "y" ]; then
        main_menu
        return
    fi
    
    echo -e "\n${YELLOW}Removing services...${NC}"
    systemctl stop xray 2>/dev/null || true
    systemctl disable xray 2>/dev/null || true
    systemctl stop caddy 2>/dev/null || true
    systemctl disable caddy 2>/dev/null || true
    systemctl stop dnstt 2>/dev/null || true
    systemctl disable dnstt 2>/dev/null || true
    
    echo -e "${YELLOW}Removing files...${NC}"
    rm -rf /usr/local/bin/xray
    rm -rf /usr/local/etc/xray
    rm -rf /etc/systemd/system/xray*
    rm -rf /etc/caddy
    rm -rf /usr/local/bin/dnstt-server
    rm -rf /etc/systemd/system/dnstt*
    rm -rf /root/onetap-config.txt
    
    echo -e "\n${GREEN}✓ Uninstall complete${NC}\n"
    exit 0
}

# Helper Functions

install_dependencies() {
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        apt-get update -qq
        apt-get install -y curl wget qrencode jq ufw dnsutils dig >/dev/null 2>&1
    else
        echo -e "${RED}Unsupported OS${NC}"
        exit 1
    fi
}

install_xray() {
    if [ ! -f /usr/local/bin/xray ]; then
        bash <(curl -sL https://github.com/XTLS/Xray-install/raw/main/install-release.sh) install >/dev/null 2>&1
    fi
}

install_caddy() {
    if ! command -v caddy &> /dev/null; then
        apt install -y debian-keyring debian-archive-keyring apt-transport-https curl >/dev/null 2>&1
        curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' 2>/dev/null | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg 2>/dev/null
        curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' 2>/dev/null | tee /etc/apt/sources.list.d/caddy-stable.list >/dev/null 2>&1
        apt update -qq
        apt install caddy -y >/dev/null 2>&1
    fi
}

install_dnstt() {
    # Download and install dnstt
    wget -q https://github.com/farhadsaket/dnstt/releases/download/v1.20230712.0/dnstt-20230712.0-linux-amd64.tar.gz
    tar -xzf dnstt-20230712.0-linux-amd64.tar.gz
    mv dnstt-server /usr/local/bin/
    chmod +x /usr/local/bin/dnstt-server
    rm -f dnstt-20230712.0-linux-amd64.tar.gz
}

configure_firewall() {
    # Configure UFW
    if command -v ufw &> /dev/null; then
        ufw --force enable >/dev/null 2>&1
        ufw allow 22/tcp >/dev/null 2>&1
        ufw allow 80/tcp >/dev/null 2>&1
        ufw allow 443/tcp >/dev/null 2>&1
        ufw allow 8443/tcp >/dev/null 2>&1
        ufw allow 2053/tcp >/dev/null 2>&1
        ufw allow 2083/tcp >/dev/null 2>&1
        ufw allow 2087/tcp >/dev/null 2>&1
        ufw allow 2096/tcp >/dev/null 2>&1
        ufw allow 53/udp >/dev/null 2>&1
        ufw reload >/dev/null 2>&1
    fi
}

setup_reality() {
    local server_ip=$1
    UUID=$(cat /proc/sys/kernel/random/uuid)
    
    # Generate Reality keys
    KEYS=$(/usr/local/bin/xray x25519)
    PRIVATE_KEY=$(echo "$KEYS" | grep "Private key:" | awk '{print $3}')
    PUBLIC_KEY=$(echo "$KEYS" | grep "Public key:" | awk '{print $3}')
    SHORT_ID=$(openssl rand -hex 8)
    
    # Create config with proper settings
    cat > /usr/local/etc/xray/config.json << EOF
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [{
    "listen": "0.0.0.0",
    "port": 443,
    "protocol": "vless",
    "settings": {
      "clients": [{
        "id": "$UUID",
        "flow": "xtls-rprx-vision"
      }],
      "decryption": "none"
    },
    "streamSettings": {
      "network": "tcp",
      "security": "reality",
      "realitySettings": {
        "show": false,
        "dest": "www.microsoft.com:443",
        "xver": 0,
        "serverNames": ["www.microsoft.com", "microsoft.com"],
        "privateKey": "$PRIVATE_KEY",
        "shortIds": ["", "$SHORT_ID"]
      }
    },
    "sniffing": {
      "enabled": true,
      "destOverride": ["http", "tls"]
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "tag": "direct"
  }, {
    "protocol": "blackhole",
    "tag": "block"
  }],
  "routing": {
    "rules": [{
      "type": "field",
      "ip": ["geoip:private"],
      "outboundTag": "block"
    }]
  }
}
EOF
    
    # Enable and start
    systemctl enable xray >/dev/null 2>&1
    systemctl restart xray
    
    # Wait for service to start
    sleep 2
    
    # Check if service is running
    if ! systemctl is-active --quiet xray; then
        echo -e "${RED}Error: Xray failed to start!${NC}"
        echo -e "${YELLOW}Checking logs...${NC}"
        journalctl -u xray -n 20 --no-pager
        return 1
    fi
    
    # Save config
    CONFIG_LINK="vless://$UUID@$server_ip:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.microsoft.com&fp=chrome&pbk=$PUBLIC_KEY&sid=$SHORT_ID&type=tcp&headerType=none#oneTap-Reality"
    
    cat > /root/onetap-config.txt << EOF
═══════════════════════════════════════
        oneTap Quick Setup Config
═══════════════════════════════════════

Server IP: $server_ip
UUID: $UUID
Protocol: VLESS + Reality
Port: 443
Public Key: $PUBLIC_KEY
Short ID: $SHORT_ID

Connection Link:
$CONFIG_LINK

Scan QR Code with your phone:
EOF
    
    echo "$CONFIG_LINK" | qrencode -t ANSIUTF8 >> /root/onetap-config.txt 2>/dev/null || echo "(QR code generation failed)" >> /root/onetap-config.txt
    
    cat >> /root/onetap-config.txt << EOF

Apps to use:
  Android: v2rayNG, MahsaNG
  iOS: Streisand, Shadowrocket
  Windows: v2rayN
  
How to connect:
  1. Install app from above
  2. Click + or Add
  3. Choose "Import from Clipboard"
  4. Copy the link above
  5. Paste and connect!

═══════════════════════════════════════
EOF
}

show_quick_config() {
    cat /root/onetap-config.txt
    
    echo -e "\n${GREEN}Configuration saved to: /root/onetap-config.txt${NC}"
    echo -e "${YELLOW}You can view it anytime by choosing option 6 from menu${NC}\n"
}

setup_vless_ws_tls() {
    local domain=$1
    UUID=$(cat /proc/sys/kernel/random/uuid)
    
    # Stop Caddy if running
    systemctl stop caddy 2>/dev/null || true
    
    # Create Xray config with proper WebSocket settings
    cat > /usr/local/etc/xray/config.json << EOF
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [{
    "listen": "127.0.0.1",
    "port": 10000,
    "protocol": "vless",
    "settings": {
      "clients": [{
        "id": "$UUID",
        "level": 0
      }],
      "decryption": "none"
    },
    "streamSettings": {
      "network": "ws",
      "wsSettings": {
        "path": "/ws"
      }
    },
    "sniffing": {
      "enabled": true,
      "destOverride": ["http", "tls"]
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "tag": "direct"
  }]
}
EOF
    
    # Configure Caddy with proper reverse proxy
    cat > /etc/caddy/Caddyfile << EOF
$domain {
    @websocket {
        path /ws
    }
    
    handle @websocket {
        reverse_proxy 127.0.0.1:10000 {
            header_up X-Forwarded-For {remote_host}
        }
    }
    
    handle {
        respond "Welcome" 200
    }
    
    encode gzip
    
    log {
        output file /var/log/caddy/access.log
    }
}
EOF
    
    # Enable and start services
    systemctl enable xray >/dev/null 2>&1
    systemctl restart xray
    
    sleep 2
    
    if ! systemctl is-active --quiet xray; then
        echo -e "${RED}Error: Xray failed to start!${NC}"
        journalctl -u xray -n 20 --no-pager
        return 1
    fi
    
    systemctl enable caddy >/dev/null 2>&1
    systemctl restart caddy
    
    # Wait for SSL certificate
    echo -e "${YELLOW}Waiting for SSL certificate (this may take 30-60 seconds)...${NC}"
    sleep 10
    
    # Check Caddy status
    if ! systemctl is-active --quiet caddy; then
        echo -e "${RED}Error: Caddy failed to start!${NC}"
        journalctl -u caddy -n 20 --no-pager
        return 1
    fi
    
    CONFIG_LINK="vless://$UUID@$domain:443?encryption=none&security=tls&type=ws&host=$domain&path=%2Fws&sni=$domain#oneTap-Premium"
    
    cat > /root/onetap-config.txt << EOF
═══════════════════════════════════════
       oneTap Premium Setup Config
═══════════════════════════════════════

Domain: $domain
UUID: $UUID
Protocol: VLESS + WebSocket + TLS
Port: 443
Path: /ws

Connection Link:
$CONFIG_LINK

Scan QR Code:
EOF
    
    echo "$CONFIG_LINK" | qrencode -t ANSIUTF8 >> /root/onetap-config.txt 2>/dev/null || echo "(QR code generation failed)" >> /root/onetap-config.txt
    
    cat >> /root/onetap-config.txt << EOF

Apps to use:
  Android: v2rayNG, MahsaNG
  iOS: Streisand, Shadowrocket
  Windows: v2rayN

Testing:
  Wait 1-2 minutes for SSL certificate
  Then test the connection

═══════════════════════════════════════
EOF
}

show_premium_config() {
    cat /root/onetap-config.txt
    echo -e "\n${GREEN}Configuration saved to: /root/onetap-config.txt${NC}\n"
    echo -e "${YELLOW}Note: If connection fails, wait 2-3 minutes for SSL certificate${NC}"
    echo -e "${YELLOW}You can check Caddy logs: journalctl -u caddy -f${NC}\n"
}

setup_multi_protocol_no_domain() {
    local server_ip=$1
    UUID=$(cat /proc/sys/kernel/random/uuid)
    TROJAN_PASS=$(openssl rand -base64 16)
    SS_PASS=$(openssl rand -base64 16)
    
    # Generate Reality keys
    KEYS=$(/usr/local/bin/xray x25519)
    PRIVATE_KEY=$(echo "$KEYS" | grep "Private key:" | awk '{print $3}')
    PUBLIC_KEY=$(echo "$KEYS" | grep "Public key:" | awk '{print $3}')
    SHORT_ID=$(openssl rand -hex 8)
    
    # Create multi-protocol config
    cat > /usr/local/etc/xray/config.json << EOF
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "listen": "0.0.0.0",
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [{
          "id": "$UUID",
          "flow": "xtls-rprx-vision"
        }],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "www.microsoft.com:443",
          "xver": 0,
          "serverNames": ["www.microsoft.com"],
          "privateKey": "$PRIVATE_KEY",
          "shortIds": ["$SHORT_ID"]
        }
      }
    },
    {
      "listen": "0.0.0.0",
      "port": 8443,
      "protocol": "trojan",
      "settings": {
        "clients": [{
          "password": "$TROJAN_PASS"
        }]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "www.microsoft.com:443",
          "xver": 0,
          "serverNames": ["www.microsoft.com"],
          "privateKey": "$PRIVATE_KEY",
          "shortIds": ["$SHORT_ID"]
        }
      }
    },
    {
      "listen": "0.0.0.0",
      "port": 2053,
      "protocol": "shadowsocks",
      "settings": {
        "method": "2022-blake3-aes-128-gcm",
        "password": "$SS_PASS"
      }
    }
  ],
  "outbounds": [{
    "protocol": "freedom"
  }]
}
EOF
    
    systemctl restart xray
    
    sleep 2
    
    if ! systemctl is-active --quiet xray; then
        echo -e "${RED}Error: Xray failed to start!${NC}"
        journalctl -u xray -n 20 --no-pager
        return 1
    fi
    
    # Generate configs
    VLESS_LINK="vless://$UUID@$server_ip:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.microsoft.com&fp=chrome&pbk=$PUBLIC_KEY&sid=$SHORT_ID&type=tcp#oneTap-VLESS"
    TROJAN_LINK="trojan://$TROJAN_PASS@$server_ip:8443?security=reality&sni=www.microsoft.com&fp=chrome&pbk=$PUBLIC_KEY&sid=$SHORT_ID&type=tcp#oneTap-Trojan"
    SS_LINK="ss://$(echo -n "2022-blake3-aes-128-gcm:$SS_PASS" | base64)@$server_ip:2053#oneTap-SS"
    
    # Create subscription content
    SUB_CONTENT=$(echo -e "$VLESS_LINK\n$TROJAN_LINK\n$SS_LINK" | base64 -w 0)
    
    cat > /root/onetap-config.txt << EOF
═══════════════════════════════════════
      oneTap Advanced Setup Configs
═══════════════════════════════════════

Server IP: $server_ip

1. VLESS + Reality (Port 443):
$VLESS_LINK

2. Trojan + Reality (Port 8443):
$TROJAN_LINK

3. Shadowsocks (Port 2053):
$SS_LINK

Subscription Link (Base64):
$SUB_CONTENT

How to use:
- Try each protocol to see which works best
- VLESS usually fastest
- Trojan good for stability  
- Shadowsocks for compatibility

═══════════════════════════════════════
EOF
}

setup_multi_protocol_domain() {
    local domain=$1
    UUID=$(cat /proc/sys/kernel/random/uuid)
    TROJAN_PASS=$(openssl rand -base64 16)
    
    # Create multi-protocol config with domain
    cat > /usr/local/etc/xray/config.json << EOF
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "listen": "127.0.0.1",
      "port": 10000,
      "protocol": "vless",
      "settings": {
        "clients": [{
          "id": "$UUID"
        }],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/vless"
        }
      }
    },
    {
      "listen": "127.0.0.1",
      "port": 10001,
      "protocol": "trojan",
      "settings": {
        "clients": [{
          "password": "$TROJAN_PASS"
        }]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/trojan"
        }
      }
    }
  ],
  "outbounds": [{
    "protocol": "freedom"
  }]
}
EOF
    
    # Configure Caddy for multiple protocols
    cat > /etc/caddy/Caddyfile << EOF
$domain {
    @vless {
        path /vless
    }
    
    @trojan {
        path /trojan
    }
    
    handle @vless {
        reverse_proxy 127.0.0.1:10000
    }
    
    handle @trojan {
        reverse_proxy 127.0.0.1:10001
    }
    
    handle {
        respond "Welcome" 200
    }
}
EOF
    
    systemctl restart xray
    systemctl restart caddy
    
    sleep 5
    
    VLESS_LINK="vless://$UUID@$domain:443?encryption=none&security=tls&type=ws&host=$domain&path=%2Fvless&sni=$domain#oneTap-VLESS"
    TROJAN_LINK="trojan://$TROJAN_PASS@$domain:443?security=tls&type=ws&host=$domain&path=%2Ftrojan&sni=$domain#oneTap-Trojan"
    
    SUB_CONTENT=$(echo -e "$VLESS_LINK\n$TROJAN_LINK" | base64 -w 0)
    
    cat > /root/onetap-config.txt << EOF
═══════════════════════════════════════
      oneTap Advanced Setup Configs
═══════════════════════════════════════

Domain: $domain

1. VLESS + WS + TLS:
$VLESS_LINK

2. Trojan + WS + TLS:
$TROJAN_LINK

Subscription (Base64):
$SUB_CONTENT

═══════════════════════════════════════
EOF
}

setup_dnstt() {
    local domain=$1
    local server_ip=$2
    
    # Generate key for DNSTT
    DNSTT_KEY=$(openssl rand -hex 16)
    
    # Create systemd service
    cat > /etc/systemd/system/dnstt.service << EOF
[Unit]
Description=DNSTT Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/dnstt-server -udp :53 -privkey $DNSTT_KEY $domain 127.0.0.1:80
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable dnstt
    systemctl start dnstt
    
    cat > /root/onetap-config.txt << EOF
═══════════════════════════════════════
         oneTap DNS Tunnel Config
═══════════════════════════════════════

Domain: $domain
Server IP: $server_ip
Key: $DNSTT_KEY

DNS Records to add:
1. NS record: ns1.$domain → $server_ip
2. A record: ns1.$domain → $server_ip

Client command:
dnstt-client -doh https://dns.google/dns-query -pubkey $DNSTT_KEY $domain 127.0.0.1:1080

Then use SOCKS5 proxy: 127.0.0.1:1080

═══════════════════════════════════════
EOF
}

show_dnstt_config() {
    cat /root/onetap-config.txt
    echo -e "\n${GREEN}Configuration saved to: /root/onetap-config.txt${NC}\n"
}

show_advanced_config() {
    cat /root/onetap-config.txt 2>/dev/null || echo -e "${YELLOW}Configuration not found${NC}"
}

enable_bbr() {
    echo -e "\n${YELLOW}Enabling BBR...${NC}"
    
    # Check if already enabled
    if sysctl net.ipv4.tcp_congestion_control 2>/dev/null | grep -q bbr; then
        echo -e "${GREEN}BBR is already enabled${NC}"
        return 0
    fi
    
    # Enable BBR
    modprobe tcp_bbr
    echo "tcp_bbr" >> /etc/modules-load.d/modules.conf
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p >/dev/null 2>&1
    
    echo -e "${GREEN}✓ BBR enabled${NC}"
}

optimize_kernel() {
    echo -e "\n${YELLOW}Optimizing kernel parameters...${NC}"
    
    cat >> /etc/sysctl.conf << 'EOF'

# oneTap optimizations
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_mtu_probing = 1
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 15
EOF
    
    sysctl -p >/dev/null 2>&1
    
    echo -e "${GREEN}✓ Kernel optimized${NC}"
}

# Run main menu
main_menu
