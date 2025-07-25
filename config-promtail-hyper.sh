#!/bin/bash

# List of hosts
hosts=(
compute-1
compute-2
compute-3
compute-4
compute-5
compute-6
compute-7
compute-8
compute-9
compute-10
compute-11
compute-12
compute-13
compute-14
compute-15
compute-16
compute-17
compute-18
compute-19
compute-20
compute-21
compute-22
compute-23
compute-24
compute-25
compute-26
compute-27
compute-28
compute-29
compute-30
compute-31
compute-32
compute-33
compute-34
compute-35
compute-36
compute-37
compute-38
compute-39
compute-40
compute-41
compute-42
compute-43
compute-44
compute-45
compute-46
compute-47
compute-48
compute-49
compute-50
compute-51
compute-52
compute-53
compute-54
compute-55
compute-56
compute-57
compute-58
compute-59
compute-60
compute-61
compute-62
compute-63
compute-64
compute-65
compute-66
compute-67
)

# Path konfigurasi Promtail
# config_path="/usr/local/bin/config-promtail-hyper.yml"

# Membuat konfigurasi untuk setiap host
for host in "${hosts[@]}"; do
    echo "Creating Promtail config for ${host}..."
    ssh "${host}" "sudo cat << EOF > "/usr/local/bin/config-promtail-hyper.yml"
server:
  http_listen_port: 9081
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

client:
  url: http://172.18.251.13:3100/loki/api/v1/push

scrape_configs:
  - job_name: oslog
    static_configs:
    - targets:
        - localhost
      labels:
        host: ${host}
        job: oslog
        __path__: /var/log/{cinder,ceph,openvswitch,ovn,keystone}/*.log

  - job_name: haproxy
    static_configs:
    - targets:
        - localhost
      labels:
        host: ${host}
        job: oslog
        __path__: /var/log/haproxy.log

  - job_name: neutron
    static_configs:
    - targets:
        - localhost
      labels:
        host: ${host}
        job: neutron
        __path__: /var/log/neutron/*.log

  - job_name: nova
    static_configs:
    - targets:
        - localhost
      labels:
        host: ${host}
        job: nova
        __path__: /var/log/nova/*.log

  - job_name: ssh
    static_configs:
    - targets:
        - localhost
      labels:
        host: ${host}
        job: ssh
        __path__: /var/log/auth.log
    relabel_configs:
    - source_labels: [__address__]
      target_label: instance

  - job_name: kernel
    static_configs:
    - targets:
        - localhost
      labels:
        host: ${host}
        job: kernel
        __path__: /var/log/kern.log
EOF"
    echo "Promtail config for ${host} created."
# Restart Promtail
echo "Restarting Promtail..."
ssh  ${host} sudo systemctl restart promtail-hyper.service
echo "Promtail restarted."
done
