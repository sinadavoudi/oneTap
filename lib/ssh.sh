optimize_ssh() {
  sed -i 's/#Compression no/Compression yes/' /etc/ssh/sshd_config
  sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
  systemctl restart sshd
}
