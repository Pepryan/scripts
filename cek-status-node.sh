#!/bin/bash

remote_servers=(
10.40.1.173
10.40.1.35
172.28.220.56
10.40.27.26
10.40.27.52
10.40.1.51
10.40.8.152
10.40.30.33
10.40.5.169
10.40.5.53
10.40.5.136
10.40.5.131
10.40.5.114
10.40.27.117
10.40.1.158
10.40.27.90
10.40.5.231
10.40.5.173
10.40.5.223
10.40.5.227
10.40.27.14
10.40.27.24
10.40.27.33
10.40.27.115
10.40.27.177
10.40.9.116
10.40.1.31
10.40.5.29
10.40.5.161
10.40.5.64
10.40.5.210
10.40.5.186
10.40.1.69
10.40.1.193
10.40.1.87
10.40.1.147
10.40.1.127
10.40.1.141
10.40.5.248
10.40.1.229
10.40.1.154
10.40.1.232
10.40.1.132
10.40.1.112
10.40.1.212
10.40.5.214
10.40.5.92
10.40.5.37
10.40.1.29
10.26.2.20
10.40.7.90
10.40.8.44
10.40.8.222
172.28.216.204
10.40.17.216
10.40.30.58
10.40.30.208
10.40.17.106
10.40.17.63
)

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
      ssh -i "$ssh_key" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GSSAPIAuthentication=no -o ConnectTimeout=$timeout "$ssh_user@$remote_server" 'systemctl is-active node_exporter.service >/dev/null 2>&1'
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
