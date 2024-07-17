#!/bin/bash

SSH_KEY="~/devops.pem"
SERVICE_FILE_1="/etc/systemd/system/node_exporter.service"
SERVICE_FILE_2="/etc/systemd/system/node-exporter.service"
WEB_PARAM="web.listen-address"
TEXTFILE_PARAM="collector.textfile.directory"

# Fungsi untuk memeriksa versi node_exporter
check_node_exporter_version() {
  local ip=$1
  local user=$2
  local version
  version=$(ssh -i $SSH_KEY -n -l $user $ip -o ConnectTimeout=10 -o GSSAPIAuthentication=no -o PasswordAuthentication=no -o StrictHostKeyChecking=no "node_exporter --version 2>&1" | grep "node_exporter" | awk '{print $3}')
  if [[ $(echo -e "$version\n1.6.0" | sort -V | head -n1) != "1.6.0" ]]; then
    echo "Versi node_exporter di $ip dengan user $user kurang dari 1.6.0: $version"
    return 1
  else
    echo "Versi node_exporter di $ip dengan user $user sesuai: $version"
    return 0
  fi
}

# Fungsi untuk memeriksa dan memperbaiki konfigurasi di file service
check_service_configuration() {
  local ip=$1
  local user=$2
  local service_file_content
  local service_name

  for SERVICE_FILE in $SERVICE_FILE_1 $SERVICE_FILE_2; do
    service_file_content=$(ssh -i $SSH_KEY -n -l $user $ip -o ConnectTimeout=10 -o GSSAPIAuthentication=no -o PasswordAuthentication=no -o StrictHostKeyChecking=no "cat $SERVICE_FILE 2>/dev/null")

    if [[ $? -eq 0 ]]; then
      service_name=$(basename $SERVICE_FILE .service)

      # Cek apakah sudah ada parameter web-listen atau textfile, jika ada langsung keluar dari loop
      if echo "$service_file_content" | grep -q "$WEB_PARAM\|$TEXTFILE_PARAM"; then
        echo "File $SERVICE_FILE di $ip dengan user $user memiliki parameter konfigurasi yang diperlukan/penting"
        return 0
      fi

      # Backup file service jika tidak ada parameter web-listen atau textfile
      if ! echo "$service_file_content" | grep -q "$WEB_PARAM\|$TEXTFILE_PARAM"; then
        ssh -i $SSH_KEY -n -l $user $ip -o ConnectTimeout=10 -o GSSAPIAuthentication=no -o PasswordAuthentication=no -o StrictHostKeyChecking=no "sudo mv $SERVICE_FILE $SERVICE_FILE.bak"
        echo "Backup file $SERVICE_FILE ke $SERVICE_FILE.bak di $ip dengan user $user"
      fi

      # Buat service baru jika tidak ada file
      if [[ ! -f "$SERVICE_FILE_2" ]]; then
        ssh -i $SSH_KEY -n -l $user $ip -o ConnectTimeout=10 -o GSSAPIAuthentication=no -o PasswordAuthentication=no -o StrictHostKeyChecking=no "echo -e '[Unit]\nDescription=Node Exporter\nAfter=network.target\n\n[Service]\nUser=root\nGroup=root\nType=simple\nExecStart=/usr/local/bin/node_exporter\n\n[Install]\nWantedBy=multi-user.target' | sudo tee $SERVICE_FILE > /dev/null"
        echo "File service berhasil dibuat di $ip dengan user $user"
      fi
      
      # Reload daemon dan restart service
      ssh -i $SSH_KEY -n -l $user $ip -o ConnectTimeout=10 -o GSSAPIAuthentication=no -o PasswordAuthentication=no -o StrictHostKeyChecking=no "sudo systemctl daemon-reload && sudo systemctl restart $service_name"
      echo "Daemon reload dan restart $service_name service di $ip dengan user $user"
      
      return 0
    fi
  done

  echo "Tidak dapat menemukan file konfigurasi service di $ip dengan user $user"
  return 1
}

# Fungsi untuk melakukan tes curl dan grep
test_metrics() {
  local ip=$1
  local user=$2
  local response
  response=$(curl -s "$ip:9100/metrics" | grep 'product_serial=')
  if [[ -n $response ]]; then
    echo "Metrics ditemukan di $ip dengan user $user: $response"
  else
    echo "Metrics tidak ditemukan di $ip dengan user $user"
    return 1
  fi
}

# Fungsi utama untuk looping melalui IP dan user
main() {
  local ips=($(cat ip.txt))
  local users=("ubuntu" "cloud-user" "centos")

  for ip in "${ips[@]}"; do
    success=false
    for user in "${users[@]}"; do
      check_node_exporter_version $ip $user && \
      check_service_configuration $ip $user && \
      test_metrics $ip $user
      if [[ $? -eq 0 ]]; then
        success=true
        break
      fi
    done
    if ! $success; then
      echo "Tidak dapat melakukan pengecekan di $ip dengan user manapun"
    fi
  done
}

# Eksekusi fungsi utama
main
