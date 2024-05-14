#!/bin/bash

# Path ke Node Exporter
NODE_EXPORTER_PATHS=("/usr/local/bin/node_exporter" "/usr/bin/node_exporter")
NEW_NODE_EXPORTER_PATH="/home/ubuntu/node_exporter-1.6.0.linux-amd64/"

# Versi Node Exporter yang ingin dipasang
NEW_NODE_EXPORTER_VERSION=1.6.0

ip_file="ip.txt"
users=(ubuntu cloud-user centos)

# Fungsi untuk memeriksa versi Node Exporter di suatu IP dengan menggunakan pengguna tertentu
check_node_exporter_version() {
    local ip="$1"
    local user="$2"
    local version
    for path in "${NODE_EXPORTER_PATHS[@]}"; do
        version=$(ssh -i ~/devops.pem -l "$user" -o "ConnectTimeout=10" -o "GSSAPIAuthentication=no" -o "PasswordAuthentication=no" -o "StrictHostKeyChecking=no" "$ip" "$path" --version 2>/dev/null | grep -oP 'version \K[^ ]+')
        if [ -n "$version" ]; then
            echo "$version"
            return 0
        fi
    done
    echo "Not found"

    # echo $version
}

# Fungsi untuk memperbarui Node Exporter jika versi di bawah 1.6
update_node_exporter() {
    local ip="$1"
    local user="$2"
    local current_version=$3

    # Pisahkan versi yang sedang diuji dan versi yang diinginkan ke dalam array
    IFS='.' read -r -a current_version_array <<< "$current_version"
    IFS='.' read -r -a desired_version_array <<< "$NEW_NODE_EXPORTER_VERSION"

    # Bandingkan setiap komponen versi
    for ((i=0; i<${#desired_version_array[@]}; i++)); do
        if [ "${current_version_array[i]}" -lt "${desired_version_array[i]}" ]; then
        # if [ $current_version -lt $NEW_NODE_EXPORTER_VERSION ]; then
            echo "Memperbarui Node Exporter ke versi $NEW_NODE_EXPORTER_VERSION di $ip dengan pengguna $user ..."
            
            # Salin file Node Exporter ke tujuan yang sesuai berdasarkan jenis pengguna
            scp -i ~/devops.pem "$NEW_NODE_EXPORTER_PATH"node_exporter "$user"@"$ip":~/node_exporter

            # Salin file konfigurasi systemd
            scp -i ~/devops.pem "$NEW_NODE_EXPORTER_PATH"node_exporter.service "$user"@"$ip":~/node_exporter.service
            
            # Hentikan layanan Node Exporter
            ssh -i ~/devops.pem -l "$user" "$ip" 'sudo systemctl stop node_exporter'

            # Pindahkan file Node Exporter ke direktori yang sesuai
            if [ "$user" == "ubuntu" ]; then
                ssh -i ~/devops.pem -l "$user" "$ip" 'sudo mv ~/node_exporter /usr/local/bin/'
                ssh -i ~/devops.pem -l "$user" "$ip" 'sudo mv ~/node_exporter.service /etc/systemd/system/'
            else
                # Jika pengguna adalah centos atau cloud-user
                ssh -i ~/devops.pem -l "$user" "$ip" 'sudo mv -Z ~/node_exporter /usr/local/bin/'
                ssh -i ~/devops.pem -l "$user" "$ip" 'sudo mv -Z ~/node_exporter.service /etc/systemd/system/'
            fi

            # Atur izin file
            ssh -i ~/devops.pem -l "$user" "$ip" 'sudo chmod 644 /etc/systemd/system/node_exporter.service'

            # Reload daemon systemd
            ssh -i ~/devops.pem -l "$user" "$ip" 'sudo systemctl daemon-reload'

            # Mulai dan atur agar Node Exporter otomatis berjalan saat boot
            ssh -i ~/devops.pem -l "$user" "$ip" 'sudo systemctl start node_exporter'
            ssh -i ~/devops.pem -l "$user" "$ip" 'sudo systemctl enable node_exporter'
            
            local version_updated=$(check_node_exporter_version "$ip" "$user")
            echo "DONE. Node exporter sudah berhasil diupdate ke versi: $version_updated"
            return

        elif [ "${current_version_array[i]}" -gt "${desired_version_array[i]}" ]; then
            echo "Node Exporter sudah versi $NEW_NODE_EXPORTER_VERSION atau lebih baru di $ip dengan pengguna $user."
            return
        fi
    done

    # Jika semua komponen versi sama, maka versi Node Exporter sudah sesuai
    echo "Node Exporter sudah versi $NEW_NODE_EXPORTER_VERSION atau lebih baru di $ip dengan pengguna $user."
}

# Fungsi untuk mengubah pengguna dan grup systemd Node Exporter di suatu IP
# change_node_exporter_user_group() {
#     local ip="$1"
#     local user="$2"
#     echo "Mengubah pengguna dan grup systemd Node Exporter menjadi root di $ip dengan pengguna $user ..."
#     ssh -i ~/devops.pem -l "$user" -o "ConnectTimeout=10" -o "GSSAPIAuthentication=no" -o "PasswordAuthentication=no" -o "StrictHostKeyChecking=no" "$ip" 'echo "node_exporter  ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/node_exporter >/dev/null'
# }

# Fungsi untuk memeriksa dan melakukan tindakan yang diperlukan di setiap IP
process_ip() {
    local ip="$1"
    for user in "${users[@]}"; do
        ssh -q -i ~/devops.pem -l "$user" -o "ConnectTimeout=10" -o "GSSAPIAuthentication=no" -o "PasswordAuthentication=no" -o "StrictHostKeyChecking=no" "$ip" exit >/dev/null

        if [ "$?" -eq 0 ]; then
            local version=$(check_node_exporter_version "$ip" "$user")
            # version=expr $version
            if [ -n $version ]; then
                echo "Versi Node Exporter di $ip dengan pengguna $user: $version"
                update_node_exporter "$ip" "$user" $version
                # change_node_exporter_user_group "$ip" "$user"
                break
            fi
        else
            if [ "$user" != "centos" ]; then
                continue
            else
                echo "$ip, ISSUE: tidak bisa ssh ke instance, pindah ke IP berikutnya"
                break
            fi
        fi
    done
}

# Looping untuk setiap IP dalam file
for ip in $(cat "$ip_file"); do
    process_ip "$ip"
done

echo -e "\n"
