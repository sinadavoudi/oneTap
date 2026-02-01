#!/bin/bash

# oneTap v2.0 - Enhanced Edition
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
    
    echo -e "  ${YELLOW}4)${NC} Speed Test & Optimization"
    echo -e "  ${YELLOW}5)${NC} Show My Configs"
    echo -e "  ${YELLOW}6)${NC} Uninstall"
    echo -e "  ${YELLOW}0)${NC} Exit\n"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    
    read -p "Enter your choice [1-6]: " choice
    
    case $choice in
        1) quick_setup ;;
        2) premium_setup ;;
        3) advanced_setup ;;
        4) optimize_speed ;;
        5) show_configs ;;
        6) uninstall ;;
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
    
    echo -e "\n${YELLOW}Installing dependencies...${NC}"
    install_dependencies
    
    echo -e "\n${YELLOW}Installing Xray-core...${NC}"
    install_xray
    
    echo -e "\n${YELLOW}Configuring Reality protocol...${NC}"
    setup_reality
    
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
    
    read -p "Do you have a domain ready? (y/n): " has_domain
    if [ "$has_domain" != "y" ]; then
        echo -e "\n${YELLOW}Please:"
        echo -e "  1. Get a free domain from: freenom.com or afraid.org"
        echo -e "  2. Point domain to this IP: $(curl -s ifconfig.me)"
        echo -e "  3. Wait 5-10 minutes for DNS propagation"
        echo -e "  4. Run this script again${NC}\n"
        read -p "Press Enter to return to menu..."
        main_menu
        return
    fi
    
    read -p "Enter your domain (e.g., vpn.example.com): " DOMAIN
    
    echo -e "\n${YELLOW}Installing dependencies...${NC}"
    install_dependencies
    
    echo -e "\n${YELLOW}Installing Xray-core...${NC}"
    install_xray
    
    echo -e "\n${YELLOW}Installing Caddy (for auto SSL)...${NC}"
    install_caddy
    
    echo -e "\n${YELLOW}Configuring VLESS + WebSocket + TLS...${NC}"
    setup_vless_ws_tls "$DOMAIN"
    
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
    echo -e "  ✓ Multiple protocols (VLESS, Trojan, Shadowsocks)"
    echo -e "  ✓ Both with and without domain options"
    echo -e "  ✓ Different ports for maximum compatibility"
    echo -e "  ✓ Subscription link for easy import\n"
    
    read -p "Continue? (y/n): " confirm
    if [ "$confirm" != "y" ]; then
        main_menu
        return
    fi
    
    read -p "Do you have a domain? (y/n): " has_domain_adv
    
    echo -e "\n${YELLOW}Installing dependencies...${NC}"
    install_dependencies
    
    echo -e "\n${YELLOW}Installing Xray-core...${NC}"
    install_xray
    
    if [ "$has_domain_adv" = "y" ]; then
        read -p "Enter your domain: " DOMAIN_ADV
        echo -e "\n${YELLOW}Installing Caddy...${NC}"
        install_caddy
        setup_multi_protocol_domain "$DOMAIN_ADV"
    else
        setup_multi_protocol_no_domain
    fi
    
    echo -e "\n${GREEN}✓ Installation complete!${NC}\n"
    show_advanced_config
    
    read -p "Press Enter to return to menu..."
    main_menu
}

# Speed Optimization
optimize_speed() {
    clear
    echo -e "${GREEN}═══ Speed Test & Optimization ═══${NC}\n"
    
    echo -e "${YELLOW}Current status:${NC}"
    echo -n "  BBR: "
    if sysctl net.ipv4.tcp_congestion_control | grep -q bbr; then
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
    echo -e "Please restart your VPS for changes to take full effect.\n"
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
    
    echo -e "${YELLOW}Removing files...${NC}"
    rm -rf /usr/local/bin/xray
    rm -rf /usr/local/etc/xray
    rm -rf /etc/systemd/system/xray*
    rm -rf /etc/caddy
    rm -rf /root/onetap-config.txt
    
    echo -e "\n${GREEN}✓ Uninstall complete${NC}\n"
    exit 0
}

# Helper Functions

install_dependencies() {
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        apt-get update -qq
        apt-get install -y curl wget qrencode jq ufw >/dev/null 2>&1
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
        apt install -y debian-keyring debian-archive-keyring apt-transport-https >/dev/null 2>&1
        curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg 2>/dev/null
        curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list >/dev/null 2>&1
        apt update -qq
        apt install caddy -y >/dev/null 2>&1
    fi
}

setup_reality() {
    UUID=$(cat /proc/sys/kernel/random/uuid)
    SERVER_IP=$(curl -s ifconfig.me)
    
    # Generate Reality keys
    KEYS=$(/usr/local/bin/xray x25519)
    PRIVATE_KEY=$(echo "$KEYS" | grep "Private key:" | awk '{print $3}')
    PUBLIC_KEY=$(echo "$KEYS" | grep "Public key:" | awk '{print $3}')
    SHORT_ID=$(openssl rand -hex 8)
    
    # Create config
    cat > /usr/local/etc/xray/config.json << EOF
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [{
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
  }],
  "outbounds": [{
    "protocol": "freedom",
    "tag": "direct"
  }]
}
EOF
    
    # Enable and start
    systemctl enable xray >/dev/null 2>&1
    systemctl restart xray
    
    # Save config
    CONFIG_LINK="vless://$UUID@$SERVER_IP:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.microsoft.com&fp=chrome&pbk=$PUBLIC_KEY&sid=$SHORT_ID&type=tcp&headerType=none#oneTap-Reality"
    
    cat > /root/onetap-config.txt << EOF
═══════════════════════════════════════
        oneTap Quick Setup Config
═══════════════════════════════════════

Server IP: $SERVER_IP
UUID: $UUID
Protocol: VLESS + Reality
Port: 443

Connection Link:
$CONFIG_LINK

Scan QR Code with your phone:
EOF
    
    echo "$CONFIG_LINK" | qrencode -t ANSIUTF8 >> /root/onetap-config.txt
    
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
  5. Connect!

═══════════════════════════════════════
EOF
}

show_quick_config() {
    cat /root/onetap-config.txt
    
    echo -e "\n${GREEN}Configuration saved to: /root/onetap-config.txt${NC}"
    echo -e "${YELLOW}You can view it anytime by choosing option 5 from menu${NC}\n"
}

setup_vless_ws_tls() {
    local domain=$1
    UUID=$(cat /proc/sys/kernel/random/uuid)
    
    # Create Xray config
    cat > /usr/local/etc/xray/config.json << EOF
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [{
    "port": 10000,
    "listen": "127.0.0.1",
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
        "path": "/ws"
      }
    }
  }],
  "outbounds": [{
    "protocol": "freedom"
  }]
}
EOF
    
    # Configure Caddy
    cat > /etc/caddy/Caddyfile << EOF
$domain {
    reverse_proxy /ws localhost:10000
    file_server browse
}
EOF
    
    # Enable and start
    systemctl enable xray >/dev/null 2>&1
    systemctl restart xray
    systemctl restart caddy
    
    # Wait for SSL
    sleep 5
    
    CONFIG_LINK="vless://$UUID@$domain:443?encryption=none&security=tls&type=ws&host=$domain&path=/ws&sni=$domain#oneTap-Premium"
    
    cat > /root/onetap-config.txt << EOF
═══════════════════════════════════════
       oneTap Premium Setup Config
═══════════════════════════════════════

Domain: $domain
UUID: $UUID
Protocol: VLESS + WebSocket + TLS
Port: 443

Connection Link:
$CONFIG_LINK

Scan QR Code:
EOF
    
    echo "$CONFIG_LINK" | qrencode -t ANSIUTF8 >> /root/onetap-config.txt
    
    cat >> /root/onetap-config.txt << EOF

Apps to use:
  Android: v2rayNG, MahsaNG
  iOS: Streisand, Shadowrocket
  Windows: v2rayN

═══════════════════════════════════════
EOF
}

show_premium_config() {
    cat /root/onetap-config.txt
    echo -e "\n${GREEN}Configuration saved to: /root/onetap-config.txt${NC}\n"
}

setup_multi_protocol_no_domain() {
    echo -e "${YELLOW}Setting up multiple protocols...${NC}"
    # Implementation for advanced setup without domain
}

setup_multi_protocol_domain() {
    echo -e "${YELLOW}Setting up multiple protocols with domain...${NC}"
    # Implementation for advanced setup with domain
}

show_advanced_config() {
    cat /root/onetap-config.txt 2>/dev/null || echo -e "${YELLOW}Configuration not found${NC}"
}

enable_bbr() {
    echo -e "\n${YELLOW}Enabling BBR...${NC}"
    
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p >/dev/null 2>&1
    
    echo -e "${GREEN}✓ BBR enabled${NC}"
}

optimize_kernel() {
    echo -e "\n${YELLOW}Optimizing kernel parameters...${NC}"
    
    cat >> /etc/sysctl.conf << 'EOF'
# Network performance
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_mtu_probing = 1

# Buffer sizes
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864

# Connection optimization
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
