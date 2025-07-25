#!/bin/bash

# List of server hostnames and corresponding IPs
servers=($(cat ip-expired.txt))

for server_info in "${servers[@]}"; do
    IFS=',' read -ra server_parts <<< "$server_info"
    ip="${server_parts[0]}"
    distro="${server_parts[1],,}"  # Convert distro to lowercase
    key="~/devops.pem"
    timeout=5
    
    if [[ $distro == *"rhel"* ]]; then
        username="cloud-user"
    elif [[ $distro == *"centos"* ]]; then
        username="centos"
    else
        echo "Unknown distro in server info: $server_info"
        continue
    fi

    users=$(ssh "$username@$ip" -i "$key" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GSSAPIAuthentication=no -o ConnectTimeout=$timeout "awk -F: '\$3 >= 1000 || \$3 == 0 && \$1 != \"root\" {print \$1}' /etc/passwd 2>/dev/null")

    if [ -n "$users" ]; then
        for user in $users; do
            exp_date=$(ssh "$username@$ip" -i "$key" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GSSAPIAuthentication=no -o ConnectTimeout=$timeout "sudo chage -l $user 2>/dev/null | grep 'Password expires' | awk -F ': ' '{print \$2}'")
            if [ -n "$exp_date" ] && [ "$exp_date" != "never" ]; then
                current_date=$(date +"%Y-%m-%d")
                days_left=$(( ($(date -d "$exp_date" +"%s") - $(date -d "$current_date" +"%s")) / 86400 ))

                echo "Server: $ip, Distro: $distro, Username: $user, Days Left: $days_left"
            else
                echo "No expiration date found for $user on $ip"
            fi
        done
    else
        echo "No non-root users found on $ip"
    fi
done
