# oneTap v2.1

**Transform your VPS into a personal proxy with one command - For everyone!**

[![Version](https://img.shields.io/badge/version-2.1-blue.svg)](https://github.com/sinadavoudi/oneTap)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![OS](https://img.shields.io/badge/os-Ubuntu%20%7C%20Debian-orange.svg)]()

---

## 🎯 What is oneTap?

**oneTap** is a simple, automated script that converts your VPS into a secure personal proxy server. Designed for users without technical knowledge, it provides multiple protocols and configuration modes to bypass internet restrictions.

**Perfect for:**
- 🌍 Users facing internet censorship
- 🔒 Those who want privacy and security
- 💰 People seeking unlimited traffic at minimal cost
- 🚀 Anyone who needs fast, reliable connections

---

## ✨ Features

### 🎮 Multiple Protocol Support

1. **Quick Setup (TCP)** - No domain needed ⚡
   - Fast VLESS over TCP
   - HTTP header obfuscation
   - Works immediately
   - Best for beginners

2. **Premium Setup (WS+TLS)** - With domain 💎
   - VLESS + WebSocket + TLS
   - Automatic SSL certificates
   - Better quality and security
   - Harder to detect

3. **DNS Tunnel (DNSTT)** - For heavy filtering 🔧
   - Works over DNS protocol (port 53)
   - Bypasses deep packet inspection
   - When other methods fail

4. **Ping Tunnel (ICMP)** - For extreme blocking 🏓
   - Uses ICMP (ping) packets
   - Works when everything else is blocked
   - Emergency backup method

### 🎨 Configuration Modes

- **Auto Mode** (Recommended)
  - Random SNI, ports, and paths
  - Optimized for Iran
  - Quick one-click setup
  - Security through randomization

- **Manual Mode** (Advanced)
  - Full customization
  - Choose your own SNI, ports, paths
  - Fine-tune for your ISP
  - Maximum control

### 🚀 Additional Features

- ✅ **BBR Speed Optimization** - 2-10x faster connections
- ✅ **QR Code Generation** - Easy mobile setup
- ✅ **Auto Firewall Configuration** - Secure by default
- ✅ **Iranian Host Priority** - Better compatibility in Iran
- ✅ **Multiple SNI Options** - Random selection for security
- ✅ **One-Command Installation** - No technical knowledge needed

---

## 🚀 Quick Start (1 Minute)

### Prerequisites

- A VPS running Ubuntu 20.04+ or Debian 10+
- Root access (or sudo privileges)
- Port 443 available (or custom port)

### Installation

**One-line installer:**

```bash
bash <(curl -Ls https://raw.githubusercontent.com/sinadavoudi/oneTap/main/onetap-v2.1.sh)
```

**Or download and run:**

```bash
wget https://raw.githubusercontent.com/sinadavoudi/oneTap/main/onetap-v2.1.sh
chmod +x onetap-v2.1.sh
sudo ./onetap-v2.1.sh
```

### Main Menu

```
═══════════════════════════════════════
Choose your setup:

  1) Quick Setup (TCP - No domain) ← Recommended
  2) Premium Setup (WS+TLS - With domain)
  3) Advanced Setup (Multiple protocols)
  4) DNS Tunnel (DNSTT - For heavy filtering)
  5) Ping Tunnel (ICMP - When everything blocked)
  6) Speed Optimization (Enable BBR)
  7) Show My Configs
  8) Uninstall
  0) Exit
═══════════════════════════════════════
```

**That's it!** Copy the config link or scan the QR code and connect.

---

## 📖 Setup Options

### 1️⃣ Quick Setup (Recommended)

**Best for:** Beginners, no domain needed

**Features:**
- ✅ No domain required
- ✅ Instant setup (2 minutes)
- ✅ Auto/Manual configuration modes
- ✅ Iranian hosts prioritized
- ✅ QR code generation

**Steps:**
```bash
./onetap-v2.1.sh
1 (Quick Setup)
1 (Auto Mode) or 2 (Manual Mode)
Copy config or scan QR code
```

---

### 2️⃣ Premium Setup (With Domain)

**Best for:** Best quality, users with domains

**Requirements:**
- Domain name (free options available)
- DNS pointed to VPS IP
- Ports 80 and 443 open


**Steps:**
```bash
Point domain → VPS IP
Wait 5 minutes
./onetap-v2.1.sh → Option 2
Enter domain
Choose Auto/Manual mode
Wait for SSL (30s)
```

---

### 4️⃣ DNS Tunnel (DNSTT)

**Best for:** Heavy filtering, DNS-based bypass

**Requirements:**
- Domain with NS record access

**DNS Records Needed:**
```
A Record:  ns1.yourdomain.com → YOUR_IP
NS Record: yourdomain.com → ns1.yourdomain.com
```

**Client:**
```bash
dnstt-client -doh https://dns.google/dns-query \
  -pubkey KEY yourdomain.com 127.0.0.1:1080
```

---

### 5️⃣ Ping Tunnel (ICMP)

**Best for:** Extreme filtering, when everything fails

**When to use:**
- All TCP/UDP blocked
- Only ping allowed
- Emergency backup

**Setup:**
```bash
./onetap-v2.1.sh → Option 5
[Automatic installation]

# Client
pingtunnel-client YOUR_IP 9090
```

**Test first:**
```bash
ping YOUR_IP
```
If ping works → tunnel works!

**Client Download:**
[PingTunnel Client](https://github.com/HexaSoftwareDev/PingTunnel-Client/releases)

---

## 📱 Client Applications

### Android
- [v2rayNG](https://github.com/2dust/v2rayNG/releases/latest)
- [MahsaNG](https://github.com/GFW-knocker/MahsaNG/releases/latest) (Best for Iran)

### iOS
- [Streisand](https://apps.apple.com/app/streisand/id6450534064) (Free)
- [Shadowrocket](https://apps.apple.com/app/shadowrocket/id932747118) ($2.99)

### Windows
- [v2rayN](https://github.com/2dust/v2rayN/releases/latest)

### Linux/Mac
- [v2ray-core](https://github.com/v2fly/v2ray-core/releases)

---

## 🎮 How to Connect

### Mobile (v2rayNG)

1. Install v2rayNG or MahsaNG
2. Tap **+** → **Import from clipboard**
3. Paste config link
4. Connect

**Or scan QR code:**
- Tap **+** → **Scan QR code**
- Scan code from oneTap
- Connect

### Desktop (v2rayN)

1. Run v2rayN
2. **Subscription** → **Subscription Setting**
3. **Add** → Paste link
4. **Update Subscription**
5. Select server → **Enter**

---

## ⚡ Speed Optimization

### Enable BBR (Recommended)

```bash
./onetap-v2.1.sh
6 (Speed Optimization)
```

**Results:**
- Without BBR: 10 Mbps
- With BBR: 50-100 Mbps 🚀

**What is BBR?**
Google's TCP congestion control algorithm for 2-10x speed improvement.

---

## 🔧 Configuration Modes

### Auto Mode (Recommended)

**Iranian SNI Hosts:**
- www.speedtest.net
- zula.ir
- www.digikala.com
- www.snapp.ir
- www.aparat.com
- www.isna.ir
- www.irancell.ir

**Random WebSocket Paths:**
- /ws, /api/v1, /graphql
- /socket.io, /vless
- /download, /update

**Benefits:**
- ✅ Different config each time
- ✅ Harder to fingerprint
- ✅ Security through randomization

### Manual Mode

**Full control over:**
- SNI (Server Name Indication)
- Ports (443, 8443, 2053, etc.)
- WebSocket paths
- Host headers
- Fingerprints

---

## 🛡️ Security

### What We Do
- ✅ TLS/VLESS encryption
- ✅ No logging
- ✅ Auto firewall config
- ✅ Personal server (only you)
- ✅ Open source

### What We Don't Do
- ❌ No data collection
- ❌ No backdoors
- ❌ No third parties
- ❌ No traffic limits

### Best Practices
1. Use strong SSH passwords
2. Enable SSH key auth
3. Keep system updated
4. Don't share configs
5. Monitor usage

---

## 🔍 Troubleshooting

### Can't Connect

**Check:**
```bash
# Service status
systemctl status xray

# Logs
journalctl -u xray -f

# Firewall
ufw status

# Port availability
lsof -i :443
```

### Slow Speed

**Solutions:**
1. Enable BBR (option 6)
2. Try different VPS
3. Use Premium setup
4. Test different SNI
5. Check VPS load: `htop`

### Premium Setup Fails

**Common issues:**
1. DNS not propagated → Wait 10 min
2. Ports busy → `systemctl stop nginx apache2`
3. Wrong domain → Check DNS: `dig yourdomain.com`

---

## 📊 Comparison

| Feature | oneTap | X-UI | Manual Setup |
|---------|--------|------|--------------|
| Setup Time | 1 min | 10 min | 30+ min |
| Knowledge | None | Medium | Advanced |
| Protocols | 5 | 10+ | All |
| Auto Mode | ✅ | ❌ | ❌ |
| QR Codes | ✅ | ✅ | ❌ |
| BBR | ✅ | ✅ | Manual |

---

## 🗺️ Roadmap

### v2.2 (Coming Soon)
- [ ] Web panel
- [ ] Traffic stats
- [ ] Multi-user support
- [ ] Telegram bot
- [ ] More protocols

### v3.0 (Future)
- [ ] CDN integration
- [ ] IPv6 support
- [ ] Docker image
- [ ] Mobile companion app

---

## 🤝 Contributing

**Ways to help:**
- 🐛 Report bugs
- 💡 Suggest features
- 📖 Improve docs
- 🧪 Test on different systems
- ⭐ Star the repo

**Code contributions:**
1. Fork repo
2. Create branch: `git checkout -b feature/name`
3. Commit: `git commit -m 'Add feature'`
4. Push: `git push origin feature/name`
5. Open Pull Request

---

## 📜 License

MIT License - See [LICENSE](LICENSE) file

---

## 🙏 Acknowledgments

Built with:
- [Xray-core](https://github.com/XTLS/Xray-core)
- [Caddy](https://caddyserver.com/)
- [DNSTT](https://github.com/farhadsaket/dnstt)
- [PingTunnel](https://github.com/HexaSoftwareDev/PingTunnel-Server)

Thanks to:
- All contributors
- Iranian tech community
- Everyone fighting for internet freedom

---

## 📞 Support

- **Issues:** [GitHub Issues](https://github.com/sinadavoudi/oneTap/issues)
- **Discussions:** [GitHub Discussions](https://github.com/sinadavoudi/oneTap/discussions)

---

## ⭐ Show Your Support

If oneTap helped you:
- ⭐ Star this repo
- 🔄 Share with friends
- 🐛 Report bugs
- 💡 Suggest features

---

**Made with ❤️ for free internet access**

*Information freedom is everyone's right*
