# oneTap

**oneTap** is a terminal-only, one-command tool that turns a VPS into instant, private access.

No panels. No dashboards. No browser.

## What it does
- Creates isolated SSH access profiles
- Uses key-based authentication (no passwords)
- Outputs a one-line connection command
- Designed for non-technical users

## Requirements
- Ubuntu 20.04+ (or compatible)
- Root access
- OpenSSH server

## Install
```bash
git clone https://github.com/sinadavoudi/oneTap.git
cd oneTap
chmod +x install.sh
./install.sh
```

## Usage
Run the script and follow the menu:
- Create access profile
- List profiles
- Revoke profile

## Connect
oneTap outputs a ready command like:
```bash
ssh -i keyfile -N -D 1080 user@server
```
This creates a local SOCKS proxy on port 1080.

## Philosophy
- Speed over cleverness
- Ownership over convenience
- Boring over fragile

## License
MIT
