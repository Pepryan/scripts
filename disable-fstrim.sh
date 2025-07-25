#!/bin/bash

username="ubuntu"

# Loop melalui setiap alamat IP dalam list.txt
for ip in $(cat fstrim.txt); do
  echo "Connecting to $ip..."
  # Melakukan SSH ke alamat IP dan menjalankan perintah
  ssh "$username@$ip" "sudo systemctl disable --now fstrim.timer"
  if [ $? -eq 0 ]; then
    echo "Command executed successfully on $ip"
  else
    echo "Failed to execute command on $ip"
  fi
done
