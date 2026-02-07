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

    # Update package lists first
    apt update -qq 2>&1 | grep -i error && echo "Warning: apt update had issues"

    # Install prerequisites
    apt install -y debian-keyring debian-archive-keyring apt-transport-https curl 2>&1 | grep -i "error\|failed" && echo "Warning: prerequisite installation issues"

    # Add Caddy repository
    echo "Adding Caddy repository..."
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' 2>/dev/null | \
        gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg 2>/dev/null

    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' 2>/dev/null | \
        tee /etc/apt/sources.list.d/caddy-stable.list >/dev/null

    # Update with new repository
    echo "Updating package lists..."
    apt update -qq 2>&1 | grep -i error && echo "Warning: apt update had issues"

    # Install Caddy
    echo "Installing Caddy package..."
    apt install caddy -y 2>&1 | tee /tmp/caddy-install.log | grep -i "error\|failed"

    # Wait a moment for installation to complete
    sleep 2

    # Verify installation
    if command -v caddy >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Caddy installed successfully${NC}"
        # Ensure caddy user exists
        if ! id -u caddy >/dev/null 2>&1; then
            echo "Creating caddy user..."
            useradd --system --home /var/lib/caddy --shell /usr/sbin/nologin caddy
        fi
        # Clean up
        rm -f /tmp/caddy-install.log
        return 0
    else
        echo -e "${RED}✗ Caddy installation failed${NC}"
        echo "Installation log:"
        cat /tmp/caddy-install.log 2>/dev/null
        echo ""
        echo "Trying alternative installation method..."

        # Alternative: Direct download and install
        cd /tmp
        CADDY_VERSION="2.7.6"
        wget -q "https://github.com/caddyserver/caddy/releases/download/v${CADDY_VERSION}/caddy_${CADDY_VERSION}_linux_amd64.deb" -O caddy.deb

        if [ -f caddy.deb ]; then
            dpkg -i caddy.deb 2>&1 | grep -i "error\|failed"
            rm -f caddy.deb

            if command -v caddy >/dev/null 2>&1; then
                echo -e "${GREEN}✓ Caddy installed via direct download${NC}"
                # Ensure caddy user exists
                if ! id -u caddy >/dev/null 2>&1; then
                    echo "Creating caddy user..."
                    useradd --system --home /var/lib/caddy --shell /usr/sbin/nologin caddy
                fi
                return 0
            fi
        fi

        echo -e "${RED}✗ All installation methods failed${NC}"
        echo "Please install manually:"
        echo "  wget https://github.com/caddyserver/caddy/releases/download/v2.7.6/caddy_2.7.6_linux_amd64.deb"
        echo "  dpkg -i caddy_2.7.6_linux_amd64.deb"
        return 1
    fi
}

# Install DNSTT using dnstt-deploy
install_dnstt() {
    if systemctl is-active --quiet dnstt 2>/dev/null; then
        echo -e "${GREEN}✓ DNSTT already installed${NC}"
        return 0
    fi

    echo -e "${YELLOW}Installing DNSTT using dnstt-deploy...${NC}"

    # Download and run the official installer non-interactively
    curl -Ls https://raw.githubusercontent.com/bugfloyd/dnstt-deploy/main/dnstt-deploy.sh -o /tmp/dnstt-deploy.sh

    if [ ! -f /tmp/dnstt-deploy.sh ]; then
        echo -e "${RED}✗ Failed to download dnstt-deploy${NC}"
        return 1
    fi

    chmod +x /tmp/dnstt-deploy.sh

    # Install dnstt-deploy to /usr/local/bin
    cp /tmp/dnstt-deploy.sh /usr/local/bin/dnstt-deploy
    chmod +x /usr/local/bin/dnstt-deploy

    rm -f /tmp/dnstt-deploy.sh

    echo -e "${GREEN}✓ dnstt-deploy installer ready${NC}"
    return 0
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

    # Delete old Quick Setup configs only (not Premium configs)
    echo "Cleaning old Quick Setup configurations..."
    rm -f /usr/local/etc/xray/config-quick.json.old
    if [ -f /usr/local/etc/xray/config-quick.json ]; then
        mv /usr/local/etc/xray/config-quick.json /usr/local/etc/xray/config-quick.json.old
    fi

    # Create NEW Xray config with WebSocket
    echo "Creating Xray configuration..."
    mkdir -p /usr/local/etc/xray
    cat > /usr/local/etc/xray/config-quick.json << EOF
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

    # Link to main config
    ln -sf /usr/local/etc/xray/config-quick.json /usr/local/etc/xray/config.json

    # Stop and restart Xray to apply new config
    systemctl stop xray 2>/dev/null || true
    sleep 1

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
        if [ -f /usr/local/etc/xray/config-quick.json.old ]; then
            echo "Restoring previous configuration..."
            mv /usr/local/etc/xray/config-quick.json.old /usr/local/etc/xray/config-quick.json
            ln -sf /usr/local/etc/xray/config-quick.json /usr/local/etc/xray/config.json
            systemctl restart xray
        fi
        return 1
    fi

    echo -e "${GREEN}✓ Xray is running${NC}"

    # Clean up old backup
    rm -f /usr/local/etc/xray/config-quick.json.old

    # URL encode the path
    ENCODED_PATH=$(echo -n "$WS_PATH" | jq -sRr @uri)

    # Generate config link - WebSocket version
    CONFIG="vless://$UUID@$ip:$PORT?encryption=none&security=none&type=ws&host=$SNI&path=$ENCODED_PATH#oneTap-Quick"

    # Save config to separate file
    cat > /root/onetap-quick-config.txt << EOF
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

    cat /root/onetap-quick-config.txt

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

    echo -e "\n${GREEN}✓ Config saved to: /root/onetap-quick-config.txt${NC}"

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

# Setup Premium (Option 2) with Auto/Manual and SNI choice
setup_premium() {
    local domain=$1
    local ip=$2
    local regenerate=${3:-false}

    if [ "$regenerate" = false ]; then
        echo -e "\n${YELLOW}═══ Setting up Premium (WS+TLS) ═══${NC}\n"

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

        echo -e "\n${BLUE}SNI/Host Options:${NC}"
        echo "  1) Use domain as SNI ($domain)"
        echo "  2) Use random Iranian host"
        read -p "Choose SNI option [1-2]: " sni_choice

        if [ "$sni_choice" = "2" ]; then
            SNI=$(get_random_sni)
            echo "Selected SNI: $SNI"
        else
            SNI=$domain
        fi

        read -p "Enter WebSocket path [default: /ws]: " CUSTOM_PATH
        WS_PATH=${CUSTOM_PATH:-/ws}

        read -p "Enter port [default: 443]: " CUSTOM_PORT
        PORT=${CUSTOM_PORT:-443}

        WS_HOST=$domain

    else
        # Auto mode - Use Iranian host by default
        echo -e "\n${GREEN}Auto Mode - Using optimized settings${NC}"
        echo -e "${YELLOW}Using random Iranian host for better compatibility${NC}"

        SNI=$(get_random_sni)
        WS_PATH=$(get_random_path)
        PORT=443
        WS_HOST=$domain
    fi

    echo -e "\n${BLUE}Configuration:${NC}"
    echo "  Domain: $domain"
    echo "  SNI: $SNI"
    echo "  Port: $PORT"
    echo "  Path: $WS_PATH"
    echo "  Host: $WS_HOST"
    echo ""

    # Test DNS (only on first setup)
    if [ "$regenerate" = false ]; then
        echo "Testing DNS..."
        RESOLVED=$(dig +short "$domain" @8.8.8.8 | tail -n1)
        if [ -z "$RESOLVED" ]; then
            echo -e "${RED}⚠ Cannot resolve domain${NC}"
        elif [ "$RESOLVED" != "$ip" ]; then
            echo -e "${YELLOW}⚠ Domain resolves to $RESOLVED, server is $ip${NC}"
        else
            echo -e "${GREEN}✓ DNS correct${NC}"
        fi
    fi

    # Clear ports (only on first setup)
    if [ "$regenerate" = false ]; then
        echo "Clearing ports 80 and $PORT..."
        clear_port 80
        clear_port $PORT
    fi

    # Delete OLD Premium configs only (not Quick Setup configs)
    echo "Cleaning old Premium configurations..."
    rm -f /usr/local/etc/xray/config-premium.json.old
    if [ -f /usr/local/etc/xray/config-premium.json ]; then
        mv /usr/local/etc/xray/config-premium.json /usr/local/etc/xray/config-premium.json.old
    fi

    # Create Xray config
    echo "Creating Xray configuration..."
    mkdir -p /usr/local/etc/xray
    cat > /usr/local/etc/xray/config-premium.json << EOF
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

    # Link to main config
    ln -sf /usr/local/etc/xray/config-premium.json /usr/local/etc/xray/config.json

    # Stop Xray before restart
    systemctl stop xray 2>/dev/null || true
    sleep 1

    # Create Caddy config
    echo "Creating Caddy configuration..."
    mkdir -p /etc/caddy
    cat > /etc/caddy/Caddyfile << EOF
$domain {
    reverse_proxy $WS_PATH 127.0.0.1:10000
    respond "OK" 200
}
EOF

    # Start Xray (only on first setup)
    if [ "$regenerate" = false ]; then
        echo "Starting Xray..."
        systemctl enable xray >/dev/null 2>&1
        systemctl restart xray
        sleep 2

        if ! systemctl is-active --quiet xray; then
            echo -e "${RED}✗ Xray failed${NC}"
            journalctl -u xray -n 10 --no-pager

            # Restore old config if exists
            if [ -f /usr/local/etc/xray/config-premium.json.old ]; then
                echo "Restoring previous configuration..."
                mv /usr/local/etc/xray/config-premium.json.old /usr/local/etc/xray/config-premium.json
                ln -sf /usr/local/etc/xray/config-premium.json /usr/local/etc/xray/config.json
                systemctl restart xray
            fi
            return 1
        fi
        echo -e "${GREEN}✓ Xray running${NC}"

        # Fix Caddy systemd service file to run as root
        echo "Configuring Caddy service..."
        cat > /etc/systemd/system/caddy.service << 'EOFSERVICE'
[Unit]
Description=Caddy Web Server
Documentation=https://caddyserver.com/docs/
After=network.target network-online.target
Requires=network-online.target

[Service]
Type=notify
User=root
Group=root
ExecStart=/usr/bin/caddy run --environ --config /etc/caddy/Caddyfile
ExecReload=/usr/bin/caddy reload --config /etc/caddy/Caddyfile --force
TimeoutStopSec=5s
LimitNOFILE=1048576
LimitNPROC=512
PrivateTmp=true
ProtectSystem=full
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOFSERVICE

        # Reload systemd
        systemctl daemon-reload

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
    else
        # Just restart on regenerate
        systemctl restart xray
        sleep 2
        if ! systemctl is-active --quiet xray; then
            echo -e "${RED}✗ Xray failed${NC}"
            journalctl -u xray -n 10 --no-pager
            return 1
        fi
    fi

    # Clean up old backup
    rm -f /usr/local/etc/xray/config-premium.json.old

    # Firewall (only on first setup)
    if [ "$regenerate" = false ]; then
        ufw --force enable >/dev/null 2>&1
        ufw allow 22/tcp >/dev/null 2>&1
        ufw allow 80/tcp >/dev/null 2>&1
        ufw allow $PORT/tcp >/dev/null 2>&1
        ufw reload >/dev/null 2>&1
    fi

    # Generate config (URL encode path)
    ENCODED_PATH=$(echo -n "$WS_PATH" | jq -sRr @uri)
    CONFIG="vless://$UUID@$domain:$PORT?encryption=none&security=tls&type=ws&host=$WS_HOST&path=$ENCODED_PATH&sni=$SNI#oneTap-Premium"

    # Save config to separate file
    cat > /root/onetap-premium-config.txt << EOF
╔══════════════════════════════════════╗
║    oneTap - Premium Configuration    ║
╚══════════════════════════════════════╝

Domain: $domain
Port: $PORT
UUID: $UUID
Protocol: VLESS + WebSocket + TLS
SNI: $SNI
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
    echo -e "${GREEN}║      ✓ SETUP COMPLETE!              ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════╝${NC}\n"

    cat /root/onetap-premium-config.txt

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

    echo -e "\n${GREEN}✓ Config saved to: /root/onetap-premium-config.txt${NC}"

    # Regenerate option
    echo -e "\n${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${YELLOW}Options:${NC}"
    echo "  1) Test this config"
    echo "  2) Regenerate (new SNI + path)"
    echo "  3) Back to main menu"
    echo -e "${BLUE}═══════════════════════════════════════${NC}\n"

    read -p "Choose [1-3]: " regen_choice

    case $regen_choice in
        1)
            echo -e "\n${GREEN}Test the config in your app!${NC}"
            echo "If it doesn't work, come back and choose option 2."
            echo ""
            read -p "Press Enter when ready to continue..."
            setup_premium "$domain" "$ip" false
            ;;
        2)
            echo -e "\n${YELLOW}Regenerating with new SNI + path...${NC}\n"
            sleep 1
            setup_premium "$domain" "$ip" true
            ;;
        3)
            return 0
            ;;
        *)
            return 0
            ;;
    esac
}

# Setup Advanced (Option 3) - Multiple Protocols
setup_advanced() {
    local ip=$1
    local regenerate=${2:-false}

    if [ "$regenerate" = false ]; then
        echo -e "\n${YELLOW}═══ Setting up Advanced (Multiple Protocols) ═══${NC}\n"

        echo -e "This will create:"
        echo -e "  ✓ VLESS + WebSocket (Port 443)"
        echo -e "  ✓ VMess + WebSocket (Port 8443)"
        echo -e "  ✓ Trojan + WebSocket (Port 2053)"
        echo -e "  ✓ Shadowsocks (Port 2096)"
        echo ""

        read -p "Continue? (y/n): " confirm
        if [ "$confirm" != "y" ]; then
            return 0
        fi

        # Ask for config mode
        CONFIG_MODE=$(ask_config_mode)
    fi

    # Generate credentials
    VLESS_UUID=$(cat /proc/sys/kernel/random/uuid)
    VMESS_UUID=$(cat /proc/sys/kernel/random/uuid)
    VMESS_ALTERID=0
    TROJAN_PASS=$(openssl rand -base64 16 | tr -d '=+/')

    # Shadowsocks 2022 requires base64 key of exact length
    # Using chacha20-ietf-poly1305 for better compatibility
    SS_PASS=$(openssl rand -base64 16 | tr -d '=+/')
    SS_METHOD="chacha20-ietf-poly1305"

    # Configure paths and SNI
    if [ "$CONFIG_MODE" = "2" ] && [ "$regenerate" = false ]; then
        # Manual mode
        echo -e "\n${YELLOW}Manual Configuration:${NC}"

        read -p "Enter SNI/Host [default: www.speedtest.net]: " CUSTOM_SNI
        SNI=${CUSTOM_SNI:-www.speedtest.net}

        read -p "Enter VLESS path [default: /vless]: " VLESS_PATH
        VLESS_PATH=${VLESS_PATH:-/vless}

        read -p "Enter VMess path [default: /vmess]: " VMESS_PATH
        VMESS_PATH=${VMESS_PATH:-/vmess}

        read -p "Enter Trojan path [default: /trojan]: " TROJAN_PATH
        TROJAN_PATH=${TROJAN_PATH:-/trojan}

    else
        # Auto mode
        echo -e "\n${GREEN}Auto Mode - Using random Iranian hosts and paths${NC}"
        SNI=$(get_random_sni)
        VLESS_PATH=$(get_random_path)
        VMESS_PATH=$(get_random_path)
        TROJAN_PATH=$(get_random_path)

        # Make sure paths are different
        while [ "$VMESS_PATH" = "$VLESS_PATH" ]; do
            VMESS_PATH=$(get_random_path)
        done
        while [ "$TROJAN_PATH" = "$VLESS_PATH" ] || [ "$TROJAN_PATH" = "$VMESS_PATH" ]; do
            TROJAN_PATH=$(get_random_path)
        done
    fi

    echo -e "\n${BLUE}Configuration:${NC}"
    echo "  SNI/Host: $SNI"
    echo "  VLESS Port: 443, Path: $VLESS_PATH"
    echo "  VMess Port: 8443, Path: $VMESS_PATH"
    echo "  Trojan Port: 2053, Path: $TROJAN_PATH"
    echo "  Shadowsocks Port: 2096"
    echo ""

    # Clear ports (only on first setup)
    if [ "$regenerate" = false ]; then
        echo "Clearing ports..."
        for port in 443 8443 2053 2096; do
            clear_port $port
        done
    fi

    # Delete old Advanced configs only
    echo "Cleaning old Advanced configurations..."
    rm -f /usr/local/etc/xray/config-advanced.json.old
    if [ -f /usr/local/etc/xray/config-advanced.json ]; then
        mv /usr/local/etc/xray/config-advanced.json /usr/local/etc/xray/config-advanced.json.old
    fi

    # Create Xray config with multiple protocols
    echo "Creating Xray configuration..."
    mkdir -p /usr/local/etc/xray
    cat > /usr/local/etc/xray/config-advanced.json << EOF
{
  "log": {"loglevel": "warning"},
  "inbounds": [
    {
      "listen": "0.0.0.0",
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [{"id": "$VLESS_UUID"}],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "$VLESS_PATH",
          "headers": {"Host": "$SNI"}
        }
      }
    },
    {
      "listen": "0.0.0.0",
      "port": 8443,
      "protocol": "vmess",
      "settings": {
        "clients": [{
          "id": "$VMESS_UUID",
          "alterId": $VMESS_ALTERID
        }]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "$VMESS_PATH",
          "headers": {"Host": "$SNI"}
        }
      }
    },
    {
      "listen": "0.0.0.0",
      "port": 2053,
      "protocol": "trojan",
      "settings": {
        "clients": [{"password": "$TROJAN_PASS"}]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "$TROJAN_PATH",
          "headers": {"Host": "$SNI"}
        }
      }
    },
    {
      "listen": "0.0.0.0",
      "port": 2096,
      "protocol": "shadowsocks",
      "settings": {
        "method": "$SS_METHOD",
        "password": "$SS_PASS",
        "network": "tcp,udp"
      }
    }
  ],
  "outbounds": [{"protocol": "freedom"}]
}
EOF

    # Link to main config
    ln -sf /usr/local/etc/xray/config-advanced.json /usr/local/etc/xray/config.json

    # Stop Xray before starting
    systemctl stop xray 2>/dev/null || true
    sleep 1

    # Configure firewall (only on first setup)
    if [ "$regenerate" = false ]; then
        echo "Configuring firewall..."
        ufw --force enable >/dev/null 2>&1
        ufw allow 22/tcp >/dev/null 2>&1
        ufw allow 443/tcp >/dev/null 2>&1
        ufw allow 8443/tcp >/dev/null 2>&1
        ufw allow 2053/tcp >/dev/null 2>&1
        ufw allow 2096/tcp >/dev/null 2>&1
        ufw reload >/dev/null 2>&1
    fi

    # Start/Restart Xray
    echo "Starting Xray..."
    systemctl enable xray >/dev/null 2>&1
    systemctl restart xray
    sleep 3

    if ! systemctl is-active --quiet xray; then
        echo -e "${RED}✗ Xray failed to start${NC}"
        journalctl -u xray -n 15 --no-pager

        # Restore old config if exists
        if [ -f /usr/local/etc/xray/config-advanced.json.old ]; then
            echo "Restoring previous configuration..."
            mv /usr/local/etc/xray/config-advanced.json.old /usr/local/etc/xray/config-advanced.json
            ln -sf /usr/local/etc/xray/config-advanced.json /usr/local/etc/xray/config.json
            systemctl restart xray
        fi
        return 1
    fi

    echo -e "${GREEN}✓ Xray is running${NC}"

    # Clean up old backup
    rm -f /usr/local/etc/xray/config-advanced.json.old

    # Generate config links
    VLESS_PATH_ENC=$(echo -n "$VLESS_PATH" | jq -sRr @uri)
    VMESS_PATH_ENC=$(echo -n "$VMESS_PATH" | jq -sRr @uri)
    TROJAN_PATH_ENC=$(echo -n "$TROJAN_PATH" | jq -sRr @uri)

    VLESS_LINK="vless://$VLESS_UUID@$ip:443?encryption=none&security=none&type=ws&host=$SNI&path=$VLESS_PATH_ENC#oneTap-VLESS"

    # VMess config (base64 encoded JSON)
    VMESS_JSON="{\"v\":\"2\",\"ps\":\"oneTap-VMess\",\"add\":\"$ip\",\"port\":\"8443\",\"id\":\"$VMESS_UUID\",\"aid\":\"$VMESS_ALTERID\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"$SNI\",\"path\":\"$VMESS_PATH\",\"tls\":\"\"}"
    VMESS_LINK="vmess://$(echo -n "$VMESS_JSON" | base64 -w 0)"

    TROJAN_LINK="trojan://$TROJAN_PASS@$ip:2053?security=none&type=ws&host=$SNI&path=$TROJAN_PATH_ENC#oneTap-Trojan"

    SS_LINK="ss://$(echo -n "$SS_METHOD:$SS_PASS" | base64 -w 0)@$ip:2096#oneTap-SS"

    # Create subscription (base64 of all links)
    SUB_CONTENT=$(echo -e "$VLESS_LINK\n$VMESS_LINK\n$TROJAN_LINK\n$SS_LINK" | base64 -w 0)

    # Save config
    cat > /root/onetap-advanced-config.txt << EOF
╔══════════════════════════════════════╗
║  oneTap - Advanced Multi-Protocol   ║
╚══════════════════════════════════════╝

Server IP: $ip
SNI/Host: $SNI
Config Mode: $([ "$CONFIG_MODE" = "2" ] && echo "Manual" || echo "Auto")

═══════════════════════════════════════

PROTOCOL 1: VLESS + WebSocket
Port: 443
UUID: $VLESS_UUID
Path: $VLESS_PATH

Link: $VLESS_LINK

═══════════════════════════════════════

PROTOCOL 2: VMess + WebSocket
Port: 8443
UUID: $VMESS_UUID
AlterID: $VMESS_ALTERID
Path: $VMESS_PATH

Link: $VMESS_LINK

═══════════════════════════════════════

PROTOCOL 3: Trojan + WebSocket
Port: 2053
Password: $TROJAN_PASS
Path: $TROJAN_PATH

Link: $TROJAN_LINK

═══════════════════════════════════════

PROTOCOL 4: Shadowsocks
Port: 2096
Method: $SS_METHOD
Password: $SS_PASS

Link: $SS_LINK

═══════════════════════════════════════

SUBSCRIPTION LINK (Import all at once):
$SUB_CONTENT

To use subscription:
1. Copy the subscription link above
2. In v2rayNG: ⋮ → Subscription Settings → +
3. Paste and Update
4. All 4 configs will be imported!

═══════════════════════════════════════

RECOMMENDED USAGE:
• Try VLESS first (usually fastest)
• Use VMess if VLESS blocked
• Use Trojan for stability
• Use Shadowsocks as backup

═══════════════════════════════════════
EOF

    # Display
    clear
    echo -e "${GREEN}╔══════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║      ✓ SETUP COMPLETE!              ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════╝${NC}\n"

    cat /root/onetap-advanced-config.txt

    echo -e "\n${YELLOW}QR CODES:${NC}\n"

    echo -e "${BLUE}VLESS:${NC}"
    if command -v qrencode >/dev/null 2>&1; then
        echo "$VLESS_LINK" | qrencode -t ANSIUTF8
    fi

    echo -e "\n${BLUE}VMess:${NC}"
    if command -v qrencode >/dev/null 2>&1; then
        echo "$VMESS_LINK" | qrencode -t ANSIUTF8
    fi

    echo -e "\n${GREEN}✓ Config saved to: /root/onetap-advanced-config.txt${NC}"

    # Regenerate option
    echo -e "\n${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${YELLOW}Options:${NC}"
    echo "  1) Test these configs"
    echo "  2) Regenerate (new SNI + paths)"
    echo "  3) Back to main menu"
    echo -e "${BLUE}═══════════════════════════════════════${NC}\n"

    read -p "Choose [1-3]: " regen_choice

    case $regen_choice in
        1)
            echo -e "\n${GREEN}Test the configs! Try them in order: VLESS → VMess → Trojan → SS${NC}"
            read -p "Press Enter when ready..."
            setup_advanced "$ip" false
            ;;
        2)
            echo -e "\n${YELLOW}Regenerating all protocols...${NC}\n"
            sleep 1
            setup_advanced "$ip" true
            ;;
        3)
            return 0
            ;;
        *)
            return 0
            ;;
    esac
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
    echo "     Name: ns.${DOMAIN}"
    echo "     Value: $ip"
    echo ""
    echo "  2. NS record:"
    echo "     Name: t.${DOMAIN} (or any subdomain)"
    echo "     Value: ns.${DOMAIN}"
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

    # Now run the dnstt-deploy installer interactively
    echo -e "\n${GREEN}Starting DNSTT Configuration...${NC}"
    echo -e "${YELLOW}The installer will ask you a few questions:${NC}\n"
    echo "  1. Nameserver subdomain: t.${DOMAIN}"
    echo "  2. MTU value: Press Enter for default (1232)"
    echo "  3. Tunnel mode: Choose 1 for SOCKS (recommended)"
    echo ""

    read -p "Press Enter to continue with the interactive setup..."

    # Run the installer
    /usr/local/bin/dnstt-deploy

    # Wait for service to be ready
    sleep 3

    if ! systemctl is-active --quiet dnstt; then
        echo -e "${RED}✗ DNSTT failed to start${NC}"
        echo "Please check: journalctl -u dnstt -n 20"
        return 1
    fi

    echo -e "${GREEN}✓ DNSTT is running${NC}"

    # Get the password from the systemd service
    DNSTT_PASSWORD=$(grep -oP 'ExecStart=.*-password \K[^ ]+' /etc/systemd/system/dnstt.service 2>/dev/null || echo "Check /etc/systemd/system/dnstt.service")

    # Get the actual subdomain used
    DNSTT_DOMAIN=$(grep -oP 'ExecStart=.*dnstt-server.*127\.0\.0\.1:[0-9]+ \K[^ ]+' /etc/systemd/system/dnstt.service 2>/dev/null || echo "t.${DOMAIN}")

    # Save config
    cat > /root/onetap-dnstt-config.txt << EOF
╔══════════════════════════════════════╗
║    oneTap - DNS Tunnel Config        ║
╚══════════════════════════════════════╝

Domain: $DNSTT_DOMAIN
Server IP: $ip
Port: 53 (UDP)
Protocol: DNSTT
Password: $DNSTT_PASSWORD

═══════════════════════════════════════

DNS RECORDS NEEDED:
1. A Record: ns.${DOMAIN} → $ip
2. NS Record: t.${DOMAIN} → ns.${DOMAIN}

═══════════════════════════════════════

CLIENT SETUP:

1. Download DNSTT client:
   https://dnstt.network/

2. Run client:

   dnstt-client -doh https://dns.google/dns-query \\
                -password $DNSTT_PASSWORD \\
                $DNSTT_DOMAIN 127.0.0.1:1080

3. Use SOCKS5 proxy: 127.0.0.1:1080

═══════════════════════════════════════

MANAGEMENT:
• View status: dnstt-deploy (option 3)
• View logs: dnstt-deploy (option 4)
• Reconfigure: dnstt-deploy (option 1)
• Check status: systemctl status dnstt

═══════════════════════════════════════

NOTES:
• DNS propagation can take up to 24 hours
• Test DNS setup: dig @8.8.8.8 NS t.$DOMAIN
• Mobile apps available at https://dnstt.network/

═══════════════════════════════════════
EOF

    # Display
    clear
    echo -e "${GREEN}╔══════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║      ✓ DNSTT SETUP COMPLETE!        ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════╝${NC}\n"

    cat /root/onetap-dnstt-config.txt

    echo -e "\n${GREEN}✓ Config saved to: /root/onetap-dnstt-config.txt${NC}\n"
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

# Setup AnyTLS (Option 9)
setup_anytls() {
    local ip=$1
    local regenerate=${2:-false}

    if [ "$regenerate" = false ]; then
        echo -e "\n${YELLOW}═══ Setting up AnyTLS (Camouflage) ═══${NC}\n"

        echo -e "${BLUE}AnyTLS makes your traffic look like:${NC}"
        echo -e "  • Normal HTTPS connections"
        echo -e "  • Random TLS fingerprints"
        echo -e "  • Bypasses SNI-based blocking"
        echo -e "  • No domain needed!"
        echo ""

        read -p "Continue? (y/n): " confirm
        if [ "$confirm" != "y" ]; then
            return 0
        fi

        CONFIG_MODE=$(ask_config_mode)
    fi

    # Generate UUID
    UUID=$(cat /proc/sys/kernel/random/uuid)
    echo -e "UUID: ${GREEN}$UUID${NC}"

    # Configure
    if [ "$CONFIG_MODE" = "2" ] && [ "$regenerate" = false ]; then
        # Manual mode
        echo -e "\n${YELLOW}Manual Configuration:${NC}"

        read -p "Enter SNI [default: www.speedtest.net]: " CUSTOM_SNI
        SNI=${CUSTOM_SNI:-www.speedtest.net}

        read -p "Enter port [default: 443]: " CUSTOM_PORT
        PORT=${CUSTOM_PORT:-443}

    else
        # Auto mode
        echo -e "\n${GREEN}Auto Mode - Random Iranian host${NC}"
        SNI=$(get_random_sni)
        PORT=443
    fi

    echo -e "\n${BLUE}Configuration:${NC}"
    echo "  SNI: $SNI"
    echo "  Port: $PORT"
    echo "  Protocol: VLESS + Reality (AnyTLS mode)"
    echo ""

    # Clear port
    if [ "$regenerate" = false ]; then
        clear_port $PORT
    fi

    # Delete old AnyTLS configs
    echo "Cleaning old AnyTLS configurations..."
    rm -f /usr/local/etc/xray/config-anytls.json.old
    if [ -f /usr/local/etc/xray/config-anytls.json ]; then
        mv /usr/local/etc/xray/config-anytls.json /usr/local/etc/xray/config-anytls.json.old
    fi

    # Generate Reality keys
    echo "Generating Reality keys..."
    KEY_OUTPUT=$(/usr/local/bin/xray x25519)
    PRIVATE_KEY=$(echo "$KEY_OUTPUT" | grep "PrivateKey:" | awk '{print $2}')
    PUBLIC_KEY=$(echo "$KEY_OUTPUT" | grep "Password:" | awk '{print $2}')
    SHORT_ID=$(openssl rand -hex 8)

    # Create Xray config with Reality
    echo "Creating Xray configuration..."
    mkdir -p /usr/local/etc/xray
    cat > /usr/local/etc/xray/config-anytls.json << EOF
{
  "log": {"loglevel": "warning"},
  "inbounds": [{
    "listen": "0.0.0.0",
    "port": $PORT,
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
        "dest": "$SNI:443",
        "serverNames": ["$SNI"],
        "privateKey": "$PRIVATE_KEY",
        "shortIds": ["$SHORT_ID"]
      }
    }
  }],
  "outbounds": [{"protocol": "freedom"}]
}
EOF

    # Link to main config
    ln -sf /usr/local/etc/xray/config-anytls.json /usr/local/etc/xray/config.json

    # Stop Xray before restart
    systemctl stop xray 2>/dev/null || true
    sleep 1

    # Firewall
    if [ "$regenerate" = false ]; then
        ufw allow $PORT/tcp >/dev/null 2>&1
        ufw reload >/dev/null 2>&1
    fi

    # Restart Xray
    systemctl restart xray
    sleep 3

    if ! systemctl is-active --quiet xray; then
        echo -e "${RED}✗ Xray failed${NC}"
        journalctl -u xray -n 15 --no-pager
        return 1
    fi

    echo -e "${GREEN}✓ Xray running with AnyTLS${NC}"
    rm -f /usr/local/etc/xray/config-anytls.json.old

    # Generate config
    CONFIG="vless://$UUID@$ip:$PORT?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$SNI&fp=random&pbk=$PUBLIC_KEY&sid=$SHORT_ID&type=tcp#oneTap-AnyTLS"

    # Save
    cat > /root/onetap-anytls-config.txt << EOF
╔══════════════════════════════════════╗
║     oneTap - AnyTLS Configuration    ║
╚══════════════════════════════════════╝

Server IP: $ip
Port: $PORT
UUID: $UUID
Protocol: VLESS + Reality (AnyTLS)
SNI: $SNI
Public Key: $PUBLIC_KEY
Short ID: $SHORT_ID

═══════════════════════════════════════

CONNECTION LINK:
$CONFIG

═══════════════════════════════════════
EOF

    clear
    echo -e "${GREEN}╔══════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║      ✓ ANYTLS SETUP COMPLETE!      ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════╝${NC}\n"

    cat /root/onetap-anytls-config.txt

    echo -e "\n${YELLOW}QR CODE:${NC}"
    if command -v qrencode >/dev/null 2>&1; then
        echo "$CONFIG" | qrencode -t ANSIUTF8
    fi

    echo -e "\n${GREEN}✓ Config saved to: /root/onetap-anytls-config.txt${NC}"

    # Regenerate option
    echo -e "\n${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${YELLOW}Options:${NC}"
    echo "  1) Test this config"
    echo "  2) Regenerate (new SNI)"
    echo "  3) Back to main menu"
    echo -e "${BLUE}═══════════════════════════════════════${NC}\n"

    read -p "Choose [1-3]: " regen_choice

    case $regen_choice in
        1)
            echo -e "\n${GREEN}Test the config!${NC}"
            read -p "Press Enter..."
            setup_anytls "$ip" false
            ;;
        2)
            echo -e "\n${YELLOW}Regenerating...${NC}\n"
            setup_anytls "$ip" true
            ;;
        *)
            return 0
            ;;
    esac
}

# Setup CDN (Option 10) - VLESS+WS+TLS+CDN
setup_cdn() {
    local domain=$1
    local ip=$2

    echo -e "\n${YELLOW}═══ Setting up CDN Setup (Cloudflare) ═══${NC}\n"

    echo -e "${BLUE}This setup allows you to use Cloudflare CDN:${NC}"
    echo -e "  • Hide your real server IP"
    echo -e "  • Use Cloudflare's network"
    echo -e "  • Bypass IP-based blocking"
    echo -e "  • Free SSL certificate"
    echo ""

    echo -e "${YELLOW}Requirements:${NC}"
    echo -e "  1. Domain added to Cloudflare"
    echo -e "  2. DNS record pointing to server IP"
    echo -e "  3. Cloudflare proxy ENABLED (orange cloud)"
    echo ""

    read -p "Have you set up Cloudflare? (y/n): " cf_ready
    if [ "$cf_ready" != "y" ]; then
        echo -e "\n${YELLOW}Setup Cloudflare first:${NC}"
        echo "  1. Add domain to Cloudflare (free)"
        echo "  2. Create A record: yourdomain.com → $ip"
        echo "  3. Click the cloud to make it orange (proxy enabled)"
        echo "  4. Run this script again"
        return 0
    fi

    # Install Caddy if not present
    echo -e "\n${YELLOW}Checking Caddy installation...${NC}"
    if ! command -v caddy >/dev/null 2>&1; then
        echo "Caddy not found, installing..."
        if ! install_caddy; then
            echo -e "${RED}✗ Failed to install Caddy${NC}"
            echo "Please install Caddy manually: apt install caddy"
            return 1
        fi

        # Enable Caddy service
        systemctl enable caddy >/dev/null 2>&1
    else
        echo -e "${GREEN}✓ Caddy is already installed${NC}"
    fi

    UUID=$(cat /proc/sys/kernel/random/uuid)
    WS_PATH=$(get_random_path)
    SNI=$(get_random_sni)

    echo -e "\n${BLUE}Configuration:${NC}"
    echo "  Domain: $domain"
    echo "  Path: $WS_PATH"
    echo "  SNI: $SNI"
    echo ""

    # Clear ports
    clear_port 80
    clear_port 443

    # Delete old CDN configs
    rm -f /usr/local/etc/xray/config-cdn.json.old
    if [ -f /usr/local/etc/xray/config-cdn.json ]; then
        mv /usr/local/etc/xray/config-cdn.json /usr/local/etc/xray/config-cdn.json.old
    fi

    # Create Xray config
    mkdir -p /usr/local/etc/xray
    cat > /usr/local/etc/xray/config-cdn.json << EOF
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
        "headers": {"Host": "$domain"}
      }
    }
  }],
  "outbounds": [{"protocol": "freedom"}]
}
EOF

    ln -sf /usr/local/etc/xray/config-cdn.json /usr/local/etc/xray/config.json

    # Stop services before restart
    systemctl stop xray 2>/dev/null || true
    systemctl stop caddy 2>/dev/null || true
    sleep 1

    # Create Caddy config
    mkdir -p /etc/caddy
    cat > /etc/caddy/Caddyfile << EOF
$domain {
    reverse_proxy $WS_PATH 127.0.0.1:10000
    respond "OK" 200
}
EOF

    # Configure firewall
    echo "Configuring firewall..."
    ufw allow 80/tcp >/dev/null 2>&1
    ufw allow 443/tcp >/dev/null 2>&1
    ufw reload >/dev/null 2>&1

    # Fix Caddy systemd service file to run as root
    echo "Configuring Caddy service..."
    cat > /etc/systemd/system/caddy.service << 'EOF'
[Unit]
Description=Caddy Web Server
Documentation=https://caddyserver.com/docs/
After=network.target network-online.target
Requires=network-online.target

[Service]
Type=notify
User=root
Group=root
ExecStart=/usr/bin/caddy run --environ --config /etc/caddy/Caddyfile
ExecReload=/usr/bin/caddy reload --config /etc/caddy/Caddyfile --force
TimeoutStopSec=5s
LimitNOFILE=1048576
LimitNPROC=512
PrivateTmp=true
ProtectSystem=full
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd
    systemctl daemon-reload

    # Start services
    echo "Starting Xray..."
    systemctl enable xray >/dev/null 2>&1
    systemctl restart xray
    sleep 2

    echo "Starting Caddy..."
    systemctl enable caddy >/dev/null 2>&1
    systemctl restart caddy
    sleep 5

    # Wait for SSL certificate (can take up to 30 seconds)
    echo "Waiting for SSL certificate from Let's Encrypt..."
    for i in {1..30}; do
        sleep 1
        if systemctl is-active --quiet caddy; then
            break
        fi
    done

    if ! systemctl is-active --quiet xray; then
        echo -e "${RED}✗ Xray failed to start${NC}"
        journalctl -u xray -n 15 --no-pager

        # Restore old config if exists
        if [ -f /usr/local/etc/xray/config-cdn.json.old ]; then
            echo "Restoring previous configuration..."
            mv /usr/local/etc/xray/config-cdn.json.old /usr/local/etc/xray/config-cdn.json
            ln -sf /usr/local/etc/xray/config-cdn.json /usr/local/etc/xray/config.json
            systemctl restart xray
        fi
        return 1
    fi

    if ! systemctl is-active --quiet caddy; then
        echo -e "${RED}✗ Caddy failed to start${NC}"
        echo "Checking Caddy logs..."
        journalctl -u caddy -n 15 --no-pager
        echo ""
        echo -e "${YELLOW}Common issues:${NC}"
        echo "  1. Domain DNS not pointing to this server"
        echo "  2. Port 80/443 blocked by firewall"
        echo "  3. Another service using port 80/443"
        echo ""
        echo "Fix the issue and run: systemctl restart caddy"
        return 1
    fi

    echo -e "${GREEN}✓ Services running${NC}"
    rm -f /usr/local/etc/xray/config-cdn.json.old

    # Generate config
    ENCODED_PATH=$(echo -n "$WS_PATH" | jq -sRr @uri)
    CONFIG="vless://$UUID@$domain:443?encryption=none&security=tls&type=ws&host=$domain&path=$ENCODED_PATH&sni=$SNI#oneTap-CDN"

    cat > /root/onetap-cdn-config.txt << EOF
╔══════════════════════════════════════╗
║   oneTap - CDN Setup (Cloudflare)    ║
╚══════════════════════════════════════╝

Domain: $domain
UUID: $UUID
Protocol: VLESS + WS + TLS + CDN
Path: $WS_PATH
SNI: $SNI

Your real IP is HIDDEN by Cloudflare!

═══════════════════════════════════════

CONNECTION LINK:
$CONFIG

═══════════════════════════════════════

CLOUDFLARE SETTINGS:
• SSL/TLS Mode: Full (not Flexible!)
• Proxy Status: Enabled (orange cloud)
• Min TLS Version: 1.2+

═══════════════════════════════════════
EOF

    clear
    echo -e "${GREEN}╔══════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║      ✓ CDN SETUP COMPLETE!          ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════╝${NC}\n"

    cat /root/onetap-cdn-config.txt

    echo -e "\n${YELLOW}QR CODE:${NC}"
    if command -v qrencode >/dev/null 2>&1; then
        echo "$CONFIG" | qrencode -t ANSIUTF8
    fi

    echo -e "\n${GREEN}✓ Config saved to: /root/onetap-cdn-config.txt${NC}\n"
}

# Setup TrustTunnel (Option 8) - Real Implementation
setup_trusttunnel() {
    local domain=$1
    local ip=$2

    clear
    echo -e "${YELLOW}═══ Setting up TrustTunnel (Real Protocol) ═══${NC}\n"

    echo -e "${BLUE}TrustTunnel Features:${NC}"
    echo -e "  • HTTP/2 and HTTP/3 (QUIC) support"
    echo -e "  • Perfect HTTPS mimicry"
    echo -e "  • Undetectable by DPI"
    echo -e "  • Based on real GitHub implementation"
    echo ""

    echo -e "${YELLOW}Requirements:${NC}"
    echo -e "  • Domain name"
    echo -e "  • SSL certificate (auto-generated)"
    echo -e "  • Port 443 available"
    echo ""

    read -p "Continue with TrustTunnel setup? (y/n): " confirm
    if [ "$confirm" != "y" ]; then
        main_menu
        return
    fi

    # Install dependencies
    echo -e "\n${YELLOW}Installing dependencies...${NC}"
    apt-get update -qq >/dev/null 2>&1
    apt-get install -y git golang-go >/dev/null 2>&1

    # Check Go version
    if ! command -v go &> /dev/null; then
        echo -e "${RED}✗ Go installation failed${NC}"
        read -p "Press Enter to return..."
        main_menu
        return
    fi

    echo -e "${GREEN}✓ Dependencies installed${NC}"

    # Clone TrustTunnel
    echo "Downloading TrustTunnel..."
    cd /tmp
    rm -rf TrustTunnel
    git clone https://github.com/TrustTunnel/TrustTunnel.git >/dev/null 2>&1

    if [ ! -d "TrustTunnel" ]; then
        echo -e "${RED}✗ Failed to clone TrustTunnel repository${NC}"
        read -p "Press Enter to return..."
        main_menu
        return
    fi

    # Build server
    echo "Building TrustTunnel server..."
    cd TrustTunnel/server
    go build -o /usr/local/bin/trusttunnel-server >/dev/null 2>&1

    if [ ! -f /usr/local/bin/trusttunnel-server ]; then
        echo -e "${RED}✗ Failed to build TrustTunnel${NC}"
        read -p "Press Enter to return..."
        main_menu
        return
    fi

    chmod +x /usr/local/bin/trusttunnel-server
    echo -e "${GREEN}✓ TrustTunnel built${NC}"

    # Generate password
    TT_PASSWORD=$(openssl rand -base64 24)

    # Stop conflicting services
    echo "Stopping conflicting services..."
    systemctl stop xray caddy 2>/dev/null || true
    clear_port 443

    # Install Caddy for SSL if not present
    if ! command -v caddy &> /dev/null; then
        echo "Installing Caddy for SSL..."
        install_caddy
    fi

    # Create SSL cert directory
    mkdir -p /etc/trusttunnel/certs

    # Configure Caddy for SSL certificate
    echo "Getting SSL certificate..."
    cat > /etc/caddy/Caddyfile << EOF
$domain {
    reverse_proxy localhost:8443
}
EOF

    systemctl restart caddy
    sleep 10  # Wait for SSL

    # Copy certificates
    cp /var/lib/caddy/certificates/acme-v02.api.letsencrypt.org-directory/$domain/$domain.crt /etc/trusttunnel/certs/cert.pem 2>/dev/null || {
        echo -e "${YELLOW}⚠ SSL certificate not found in expected location${NC}"
        echo "Generating self-signed certificate..."
        openssl req -x509 -newkey rsa:4096 -keyout /etc/trusttunnel/certs/key.pem \
            -out /etc/trusttunnel/certs/cert.pem -days 365 -nodes \
            -subj "/CN=$domain" >/dev/null 2>&1
    }

    cp /var/lib/caddy/certificates/acme-v02.api.letsencrypt.org-directory/$domain/$domain.key /etc/trusttunnel/certs/key.pem 2>/dev/null || true

    # Create TrustTunnel config
    cat > /etc/trusttunnel/config.json << EOF
{
    "server": {
        "listen": ":443",
        "domain": "$domain",
        "cert": "/etc/trusttunnel/certs/cert.pem",
        "key": "/etc/trusttunnel/certs/key.pem",
        "password": "$TT_PASSWORD"
    }
}
EOF

    # Create systemd service
    cat > /etc/systemd/system/trusttunnel.service << EOF
[Unit]
Description=TrustTunnel Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/trusttunnel
ExecStart=/usr/local/bin/trusttunnel-server -config /etc/trusttunnel/config.json
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    # Stop Caddy and start TrustTunnel
    systemctl stop caddy
    systemctl daemon-reload
    systemctl enable trusttunnel >/dev/null 2>&1
    systemctl start trusttunnel

    sleep 3

    if ! systemctl is-active --quiet trusttunnel; then
        echo -e "${RED}✗ TrustTunnel failed to start${NC}"
        journalctl -u trusttunnel -n 15 --no-pager
        read -p "Press Enter to return..."
        main_menu
        return
    fi

    echo -e "${GREEN}✓ TrustTunnel is running${NC}"

    # Configure firewall
    ufw allow 443/tcp >/dev/null 2>&1
    ufw allow 443/udp >/dev/null 2>&1
    ufw reload >/dev/null 2>&1

    # Save config
    cat > /root/onetap-trusttunnel-config.txt << EOF
╔══════════════════════════════════════╗
║  oneTap - TrustTunnel Configuration  ║
╚══════════════════════════════════════╝

Domain: $domain
Server IP: $ip
Port: 443 (TCP + UDP)
Password: $TT_PASSWORD
Protocol: HTTP/2 + HTTP/3 (QUIC)

═══════════════════════════════════════

CLIENT SETUP:

1. Download TrustTunnel client:
   GitHub: https://github.com/TrustTunnel/TrustTunnel/releases

   Or build from source:
   git clone https://github.com/TrustTunnel/TrustTunnel.git
   cd TrustTunnel/client
   go build

2. Create client config (config.json):
{
    "server": "$domain:443",
    "password": "$TT_PASSWORD",
    "socks5": "127.0.0.1:1080"
}

3. Run client:
   ./trusttunnel-client -config config.json

4. Use SOCKS5 proxy: 127.0.0.1:1080

═══════════════════════════════════════

MANAGEMENT:
• Check status: systemctl status trusttunnel
• View logs: journalctl -u trusttunnel -f
• Restart: systemctl restart trusttunnel
• Stop: systemctl stop trusttunnel

═══════════════════════════════════════

NOTES:
• Experimental protocol (use with caution)
• Perfect HTTPS mimicry
• Bypasses all known DPI systems
• Supports both HTTP/2 and HTTP/3

═══════════════════════════════════════
EOF

    # Display
    clear
    echo -e "${GREEN}╔══════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   ✓ TRUSTTUNNEL SETUP COMPLETE!     ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════╝${NC}\n"

    cat /root/onetap-trusttunnel-config.txt

    echo -e "\n${GREEN}✓ Config saved to: /root/onetap-trusttunnel-config.txt${NC}\n"

    read -p "Press Enter to return to menu..."
    main_menu
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
    echo -e "${GREEN}═══ Your Configurations ═══${NC}\n"

    local found=false

    # Show Quick Setup config
    if [ -f /root/onetap-quick-config.txt ]; then
        echo -e "${BLUE}━━━ Quick Setup (Option 1) ━━━${NC}\n"
        cat /root/onetap-quick-config.txt
        echo ""
        found=true
    fi

    # Show Premium config
    if [ -f /root/onetap-premium-config.txt ]; then
        echo -e "${BLUE}━━━ Premium Setup (Option 2) ━━━${NC}\n"
        cat /root/onetap-premium-config.txt
        echo ""
        found=true
    fi

    # Show Advanced config
    if [ -f /root/onetap-advanced-config.txt ]; then
        echo -e "${BLUE}━━━ Advanced Setup (Option 3) ━━━${NC}\n"
        cat /root/onetap-advanced-config.txt
        echo ""
        found=true
    fi

    # Show AnyTLS config
    if [ -f /root/onetap-anytls-config.txt ]; then
        echo -e "${BLUE}━━━ AnyTLS Setup (Option 6) ━━━${NC}\n"
        cat /root/onetap-anytls-config.txt
        echo ""
        found=true
    fi

    # Show CDN config
    if [ -f /root/onetap-cdn-config.txt ]; then
        echo -e "${BLUE}━━━ CDN Setup (Option 7) ━━━${NC}\n"
        cat /root/onetap-cdn-config.txt
        echo ""
        found=true
    fi

    # Show TrustTunnel config
    if [ -f /root/onetap-trusttunnel-config.txt ]; then
        echo -e "${BLUE}━━━ TrustTunnel (Option 8) ━━━${NC}\n"
        cat /root/onetap-trusttunnel-config.txt
        echo ""
        found=true
    fi

    # Show DNSTT config
    if [ -f /root/onetap-dnstt-config.txt ]; then
        echo -e "${BLUE}━━━ DNSTT Setup (Option 4) ━━━${NC}\n"
        cat /root/onetap-dnstt-config.txt
        echo ""
        found=true
    fi

    # Show other configs (backward compatibility)
    if [ -f /root/onetap-config.txt ]; then
        echo -e "${BLUE}━━━ Other Configuration ━━━${NC}\n"
        cat /root/onetap-config.txt
        echo ""
        found=true
    fi

    if [ "$found" = false ]; then
        echo -e "${YELLOW}No configurations found${NC}"
        echo "Please run a setup first"
    fi

    echo ""
}

# Switch active configuration
switch_config() {
    clear
    echo -e "${BLUE}═══ Switch Active Configuration ═══${NC}\n"

    # Detect available configs
    local configs=()
    local config_files=()
    local config_names=()

    if [ -f /usr/local/etc/xray/config-quick.json ]; then
        configs+=("1")
        config_files+=("/usr/local/etc/xray/config-quick.json")
        config_names+=("Quick Setup (WebSocket)")
    fi

    if [ -f /usr/local/etc/xray/config-premium.json ]; then
        configs+=("2")
        config_files+=("/usr/local/etc/xray/config-premium.json")
        config_names+=("Premium Setup (WS+TLS)")
    fi

    if [ -f /usr/local/etc/xray/config-advanced.json ]; then
        configs+=("3")
        config_files+=("/usr/local/etc/xray/config-advanced.json")
        config_names+=("Advanced Setup (4 protocols)")
    fi

    if [ -f /usr/local/etc/xray/config-anytls.json ]; then
        configs+=("6")
        config_files+=("/usr/local/etc/xray/config-anytls.json")
        config_names+=("AnyTLS (Reality)")
    fi

    if [ -f /usr/local/etc/xray/config-cdn.json ]; then
        configs+=("7")
        config_files+=("/usr/local/etc/xray/config-cdn.json")
        config_names+=("CDN Setup (Cloudflare)")
    fi

    if [ ${#configs[@]} -eq 0 ]; then
        echo -e "${YELLOW}No configurations found!${NC}"
        echo "Please create a configuration first from the main menu."
        echo ""
        read -p "Press Enter to continue..."
        return
    fi

    # Show current active config
    if [ -L /usr/local/etc/xray/config.json ]; then
        CURRENT=$(readlink /usr/local/etc/xray/config.json)
        echo -e "${GREEN}Currently Active:${NC} $(basename $CURRENT .json | sed 's/config-//')"
    else
        echo -e "${YELLOW}No active configuration${NC}"
    fi

    echo -e "\n${YELLOW}Available Configurations:${NC}\n"

    for i in "${!configs[@]}"; do
        echo -e "  ${GREEN}${configs[$i]})${NC} ${config_names[$i]}"
    done

    echo -e "\n  ${GREEN}0)${NC} Cancel"
    echo ""

    read -p "Select configuration to activate [0-7]: " choice

    # Find the selected config
    local selected_file=""
    local selected_name=""
    for i in "${!configs[@]}"; do
        if [ "${configs[$i]}" = "$choice" ]; then
            selected_file="${config_files[$i]}"
            selected_name="${config_names[$i]}"
            break
        fi
    done

    if [ "$choice" = "0" ]; then
        return
    elif [ -z "$selected_file" ]; then
        echo -e "${RED}Invalid choice${NC}"
        sleep 2
        return
    fi

    echo -e "\n${YELLOW}Switching to: $selected_name${NC}"

    # Stop services
    echo "Stopping services..."
    systemctl stop xray 2>/dev/null || true
    systemctl stop caddy 2>/dev/null || true
    sleep 1

    # Switch config
    ln -sf "$selected_file" /usr/local/etc/xray/config.json

    # Start appropriate services based on config
    echo "Starting services..."
    systemctl start xray
    sleep 2

    if ! systemctl is-active --quiet xray; then
        echo -e "${RED}✗ Xray failed to start${NC}"
        journalctl -u xray -n 10 --no-pager
        echo ""
        read -p "Press Enter to continue..."
        return
    fi

    # Start Caddy if needed (Premium, CDN, TrustTunnel)
    if [[ "$selected_file" =~ (premium|cdn|trusttunnel) ]]; then
        systemctl start caddy 2>/dev/null
        sleep 3

        if systemctl is-active --quiet caddy; then
            echo -e "${GREEN}✓ Xray and Caddy started${NC}"
        else
            echo -e "${YELLOW}⚠ Xray started, but Caddy failed (may not be needed)${NC}"
        fi
    else
        echo -e "${GREEN}✓ Xray started${NC}"
    fi

    # Show the active config
    echo -e "\n${GREEN}Configuration switched successfully!${NC}"
    echo -e "\n${BLUE}Active Configuration:${NC}"

    case "$choice" in
        1) [ -f /root/onetap-quick-config.txt ] && cat /root/onetap-quick-config.txt ;;
        2) [ -f /root/onetap-premium-config.txt ] && cat /root/onetap-premium-config.txt ;;
        3) [ -f /root/onetap-advanced-config.txt ] && cat /root/onetap-advanced-config.txt ;;
        6) [ -f /root/onetap-anytls-config.txt ] && cat /root/onetap-anytls-config.txt ;;
        7) [ -f /root/onetap-cdn-config.txt ] && cat /root/onetap-cdn-config.txt ;;
    esac

    echo ""
    read -p "Press Enter to continue..."
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
    rm -rf /usr/local/bin/dnstt-deploy
    rm -rf /etc/systemd/system/dnstt*
    rm -rf /usr/local/bin/pingtunnel
    rm -rf /etc/systemd/system/pingtunnel*
    rm -rf /root/onetap-config.txt
    rm -rf /root/onetap-dnstt-config.txt

    systemctl daemon-reload

    echo -e "${GREEN}✓ Uninstalled${NC}\n"
}

# Main menu
main_menu() {
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${GREEN}Choose your setup:${NC}\n"
    echo -e "  ${YELLOW}1)${NC} Quick Setup (WebSocket - No domain) ${GREEN}← Recommended${NC}"
    echo -e "  ${YELLOW}2)${NC} Premium Setup (WS+TLS - With domain)"
    echo -e "  ${YELLOW}3)${NC} Advanced Setup (4 protocols)"
    echo -e "  ${YELLOW}4)${NC} DNS Tunnel (DNSTT - Heavy filtering)"
    echo -e "  ${YELLOW}5)${NC} Ping Tunnel (ICMP - Everything blocked)"
    echo -e "  ${YELLOW}6)${NC} AnyTLS (Reality - Perfect camouflage) ${BLUE}← New!${NC}"
    echo -e "  ${YELLOW}7)${NC} CDN Setup (Cloudflare - Hide IP) ${BLUE}← New!${NC}"
    echo -e "  ${YELLOW}8)${NC} TrustTunnel (GitHub Implementation) ${BLUE}← Experimental${NC}"
    echo -e "  ${YELLOW}9)${NC} Speed Optimization (Enable BBR)"
    echo -e "  ${YELLOW}10)${NC} Show My Configs"
    echo -e "  ${YELLOW}11)${NC} Switch Active Configuration ${BLUE}← Fix Port Conflicts!${NC}"
    echo -e "  ${YELLOW}12)${NC} Uninstall"
    echo -e "  ${YELLOW}0)${NC} Exit"
    echo -e "${BLUE}═══════════════════════════════════════${NC}\n"

    read -p "Enter choice [0-12]: " choice

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
            if [ -z "$IP" ]; then
                read -p "Cannot detect IP. Enter manually: " IP
            fi
            install_deps
            install_xray
            setup_advanced "$IP"
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
            if [ -z "$IP" ]; then
                read -p "Cannot detect IP. Enter manually: " IP
            fi
            install_deps
            install_xray
            setup_anytls "$IP"
            ;;
        7)
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
            setup_cdn "$DOMAIN" "$IP"
            ;;
        8)
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
            setup_trusttunnel "$DOMAIN" "$IP"
            ;;
        9)
            optimize_speed
            ;;
        10)
            show_configs
            ;;
        11)
            switch_config
            ;;
        12)
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
