#!/bin/bash

remote_servers=(172.28.216.70 172.28.216.216 172.28.219.213 172.28.219.212 172.28.219.211 172.28.216.252 172.28.216.3 172.28.216.151 172.28.216.21 172.28.216.229)

ssh_key="~/devops.pem"
max_retries=1
timeout=3

for remote_server in "${remote_servers[@]}"
do
  echo "Checking node_exporter on ${remote_server}..."
  for ssh_user in "ubuntu" "cloud-user" "centos"
  do
    ssh_successful=false
    retries=0
    while ! $ssh_successful && [ $retries -lt $max_retries ]
    do
      ssh -i "$ssh_key" -o ConnectTimeout=$timeout "$ssh_user@$remote_server" 'systemctl is-active node_exporter.service >/dev/null 2>&1'
      if [ $? -eq 0 ]; then
        echo "node_exporter is active on ${remote_server} (user: ${ssh_user})"
        ssh_successful=true
      else
        echo "Unable to connect to ${remote_server} using ${ssh_user} user"
        retries=$((retries+1))
      fi
    done

    if $ssh_successful; then
      break
    fi
  done

  if ! $ssh_successful; then
    echo "Unable to check node_exporter on ${remote_server} using any user"
  fi
done
