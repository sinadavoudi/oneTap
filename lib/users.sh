create_user() {
  read -p "Username: " U
  read -s -p "Password: " P
  echo
  useradd -m -s /bin/bash "$U"
  echo "$U:$P" | chpasswd
  echo "User created"
}

delete_user() {
  read -p "Username to delete: " U
  userdel -r "$U"
}

list_users() {
  awk -F: '$3>=1000{print $1}' /etc/passwd
}
