#!/bin/bash

# Membaca daftar IP dari file ip.txt
ip=($(<ip.txt))

# Daftar pengguna
users=("ubuntu" "centos" "cloud-user")

# Path ke kunci SSH
SSH_KEY="~/devops.pem"

# Nama file service systemd
SERVICE_FILE="/etc/systemd/system/node_exporter.service"
PARAM="--collector.textfile.directory=/var/lib/node_exporter/textfile_collector/"

# Header CSV
echo "ip,user,direktori,parameter" > result-conntrack.txt

# Memeriksa setiap IP dan pengguna
for ip_address in "${ip[@]}"; do
    statusDirectory="Tidak Ada"
    statusParameterNodeExporter="Tidak Ada"

    for user in "${users[@]}"; do
        # Mengecek apakah bisa SSH ke server
        ssh_output=$(ssh -i $SSH_KEY -n -l $user $ip_address -o ConnectTimeout=10 -o GSSAPIAuthentication=no -o PasswordAuthentication=no -o StrictHostKeyChecking=no "echo SSH_OK" 2>&1)
        if [[ $ssh_output == "SSH_OK" ]]; then
            # Mengecek apakah direktori ada
            ssh -i $SSH_KEY -n -l $user $ip_address -o ConnectTimeout=10 -o GSSAPIAuthentication=no -o PasswordAuthentication=no -o StrictHostKeyChecking=no ls /var/lib/node_exporter/textfile_collector/ > /dev/null 2>&1
            exitCodeListDirectory=$?
            if [[ "$exitCodeListDirectory" -eq "0" ]]; then
                statusDirectory="Ada"
            fi

            # Mengecek apakah parameter ada di file service
            ssh -i $SSH_KEY -n -l $user $ip_address -o ConnectTimeout=10 -o GSSAPIAuthentication=no -o PasswordAuthentication=no -o StrictHostKeyChecking=no systemctl cat node_exporter.service | grep -Eo /var/lib/node_exporter/textfile_collector > /dev/null
            exitCodeCheckCollectorText=$?
            if [[ $exitCodeCheckCollectorText -eq 0 ]]; then
                statusParameterNodeExporter="Ada"
            fi

            # Output CSV
            echo "$ip_address,$user,$statusDirectory,$statusParameterNodeExporter" | tee -a result-conntrack.txt
            
            # Jika direktori ada tapi parameter tidak ada, tambahkan parameter ke file service
            # if [[ "$statusDirectory" == "Ada" && "$statusParameterNodeExporter" == "Tidak Ada" ]]; then
            #     echo "Menambahkan parameter ke $SERVICE_FILE pada $ip_address dengan pengguna $user."
            #     # Menambahkan parameter ke baris ExecStart
            #     ssh -i $SSH_KEY -n -l $user $ip_address -o ConnectTimeout=10 -o GSSAPIAuthentication=no -o PasswordAuthentication=no -o StrictHostKeyChecking=no "sudo sed -i '/ExecStart/ s/$/ $PARAM/' $SERVICE_FILE"
            #     # Reload systemd dan restart node_exporter service
            #     ssh -i $SSH_KEY -n -l $user $ip_address -o ConnectTimeout=10 -o GSSAPIAuthentication=no -o PasswordAuthentication=no -o StrictHostKeyChecking=no "sudo systemctl daemon-reload && sudo systemctl restart node_exporter"
            #     echo "Parameter ditambahkan dan service node_exporter direstart pada $ip_address dengan pengguna $user."
            # fi

            break # Keluar dari loop user jika berhasil SSH dan mengecek direktori
        fi
    done
done

