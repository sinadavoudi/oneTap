# oneTap

**Transform your VPS into a personal proxy with one command - No technical knowledge needed.**

[![Version](https://img.shields.io/badge/version-2.1-blue.svg)](https://github.com/sinadavoudi/oneTap)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![OS](https://img.shields.io/badge/os-Ubuntu%20%7C%20Debian-orange.svg)]()
[![Donate with Bitcoin](https://img.shields.io)](bitcoin:bc1qcae6zaftrae0mh3vs3nwl5seyn40fjue7enxm4)

---

## 🎯 What is oneTap?

**oneTap** is a simple bash script that converts any Ubuntu/Debian VPS into a secure personal proxy server. Designed for users in restricted regions (Iran, China, Russia), it automates the entire setup process with multiple protocol options.

**Key Features:**
- 🚀 One-command installation (2 minutes)
- 🎮 8 different protocols to choose from
- 🔍 Built-in Cloudflare Clean IP Scanner
- 🔄 Configuration switcher (no port conflicts)
- ⚡ Auto/Manual configuration modes
- 🛡️ Automatic firewall & SSL setup

---

## 📦 What You Get

| Protocol | Speed | Stealth | Domain? | Best For |
|----------|-------|---------|---------|----------|
| **VLESS+WS** | ⭐⭐⭐⭐⭐ | ⭐⭐ | ❌ | Quick start |
| **WS+TLS** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ✅ | Secure setup |
| **Reality** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ❌ | Perfect stealth |
| **CDN** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ✅ | Hide IP |
| **DNS Tunnel** | ⭐⭐⭐ | ⭐⭐⭐⭐ | ✅ | Heavy filtering |
| **ICMP Tunnel** | ⭐⭐ | ⭐⭐⭐⭐⭐ | ❌ | Extreme blocking |

---

## 🚀 Installation

### One-Line Install

```bash
bash <(curl -Ls https://raw.githubusercontent.com/sinadavoudi/oneTap/main/onetap.sh)
```

### Or Download & Run

```bash
wget https://raw.githubusercontent.com/sinadavoudi/oneTap/main/onetap.sh
chmod +x onetap.sh
sudo ./onetap.sh
```
---

## 🎮 Available Options

```
1) Quick Setup (WebSocket)           - No domain, instant setup
2) Premium Setup (WS+TLS)            - SSL encryption, needs domain  
3) Advanced Setup                    - 4 protocols at once
4) DNS Tunnel (DNSTT)                - DNS-based bypass
5) Ping Tunnel (ICMP)                - Uses ping packets
6) AnyTLS (Reality)                  - Perfect TLS camouflage
7) CDN Setup (Cloudflare)            - Hide your real IP
8) TrustTunnel                       - Experimental protocol
9) Speed Optimization (BBR)          - 2-10x speed boost
10) Show Configs                     - View all saved configs
11) Switch Configuration             - Change active protocol
12) CF Clean IP Scanner              - Find working CF IPs ⭐
13) Uninstall                        - Remove everything
```

---

## 🔧 Essential Features

### 1. CF Clean IP Scanner (Option 12)

**Critical for CDN users in Iran/China!**

Finds working Cloudflare IPs that aren't blocked in your region.

```bash
./onetap.sh → 12
Choose scan mode: 2 (Standard)
Wait 5 minutes
Copy best IP (lowest latency)
Use in your v2ray client
```

**Why needed?** Cloudflare's main IPs are blocked. Clean IPs work around this.

### 2. Configuration Switcher (Option 11)

**Prevents port conflicts when testing multiple protocols.**

```bash
./onetap.sh → 11
Select which protocol to activate
Services restart automatically
```

**Why needed?** Multiple setups use the same ports. This switches between them safely.

### 3. Auto/Manual Modes

**Auto Mode:** Random Iranian SNI, random paths, auto-configuration  
**Manual Mode:** Full control over SNI, ports, paths

---

## 📱 Client Apps

### Android
- [v2rayNG](https://github.com/2dust/v2rayNG/releases)
- [MahsaNG](https://github.com/GFW-knocker/MahsaNG/releases) (Iran optimized)

### iOS
- [Streisand](https://apps.apple.com/app/streisand/id6450534064)
- [Shadowrocket](https://apps.apple.com/app/shadowrocket/id932747118)

### Windows
- [v2rayN](https://github.com/2dust/v2rayN/releases)
- [Nekoray](https://github.com/MatsuriDayo/nekoray/releases)

### Linux/Mac
- [Nekoray](https://github.com/MatsuriDayo/nekoray/releases)

---


## ⚡ Performance Tips

### Always Do This
```bash
./onetap.sh → 9 (Enable BBR)
sudo reboot
```
**Result:** 2-10x speed improvement

### For CDN Users
- Rescan clean IPs weekly (Option 12)
- Save top 5 IPs as backup
- Test different IPs for best speed

### VPS Selection
- Closer = Faster
- Minimum: 1 CPU, 512MB RAM
- Recommended: 1 CPU, 1GB RAM

---

## 🔧 Troubleshooting

### Connection Not Working

```bash
# Check service
systemctl status xray

# Check logs
journalctl -u xray -n 50

# Check firewall
ufw status
ufw allow 443/tcp
```

### CDN Not Working in Iran

**Did you run the IP scanner?**
```bash
./onetap.sh → 12
```

**Did you use clean IP in client?**
- Server address: CLEAN_IP (from scanner)
- SNI/Host: yourdomain.com (keep your domain)

### Slow Speed

1. Enable BBR (Option 9)
2. Try different protocol
3. Rescan clean IPs (CDN users)
4. Check VPS load: `htop`

---

## 🛡️ Security

**What the script does:**
- ✅ Configures UFW firewall
- ✅ Generates unique UUIDs/passwords
- ✅ Sets up SSL certificates (for TLS options)
- ✅ No logging enabled
- ✅ Runs as systemd services

**Best practices:**
- Change SSH port from 22
- Use SSH keys instead of passwords
- Keep system updated: `apt update && apt upgrade`
- Don't share configs publicly

---

## 📖 Documentation

### Domain Setup (Options 2, 4, 7)

**Basic DNS:**
```
Type: A
Name: @ (or yourdomain.com)
Value: YOUR_VPS_IP
```

**For DNSTT (Option 4):**
```
A Record:  ns.yourdomain.com → YOUR_VPS_IP
NS Record: t.yourdomain.com → ns.yourdomain.com
```

**For CDN (Option 7):**
1. Add domain to Cloudflare (free)
2. Create A record
3. Enable proxy (orange cloud)
4. Set SSL/TLS to "Full"

### Management Commands

```bash
# View configs
./onetap.sh → 10

# Switch protocols
./onetap.sh → 11

# Check service
systemctl status xray

# View logs
journalctl -u xray -f

# Restart
systemctl restart xray
```

---

## 🆕 What's New in v2.1

- ✅ **CF Clean IP Scanner** - Find working Cloudflare IPs
- ✅ **Configuration Switcher** - No more port conflicts
- ✅ **Reality Protocol** - Perfect HTTPS camouflage
- ✅ **CDN Integration** - Hide IP with Cloudflare
- ✅ **Fixed DNSTT** - Now uses official dnstt-deploy
- ✅ **Fixed Caddy** - Auto-creates service user
- ✅ **Better error handling** - Clear error messages
- ✅ **Auto/Manual modes** - Choose complexity level

---

## 🤝 Contributing

Contributions welcome! 

- 🐛 Report bugs via [Issues](https://github.com/sinadavoudi/oneTap/issues)
- 💡 Suggest features via [Discussions](https://github.com/sinadavoudi/oneTap/discussions)
- 📖 Improve documentation
- ⭐ Star the repo if it helped you!

---

## 📜 License

MIT License - See [LICENSE](LICENSE)

---

## 🙏 Credits

Built with:
- [Xray-core](https://github.com/XTLS/Xray-core) - Proxy engine
- [Caddy](https://caddyserver.com/) - Web server
- [dnstt-deploy](https://github.com/bugfloyd/dnstt-deploy) - DNS tunnel
- [PingTunnel](https://github.com/HexaSoftwareDev/PingTunnel-Server) - ICMP tunnel

---

## ⚠️ Disclaimer

This tool is for:
- ✅ Accessing information freely
- ✅ Privacy and security
- ✅ Bypassing censorship
- ✅ Educational purposes

Not for:
- ❌ Illegal activities
- ❌ Violating terms of service
- ❌ Harmful actions

Use responsibly and respect local laws.

---

## 💬 Support

- **Documentation:** This README + in-script help
- **Issues:** [GitHub Issues](https://github.com/sinadavoudi/oneTap/issues)
- **Discussions:** [GitHub Discussions](https://github.com/sinadavoudi/oneTap/discussions)

---

**Made with ❤️ for internet freedom**

*If this helped you bypass restrictions, please ⭐ star the repo!*
