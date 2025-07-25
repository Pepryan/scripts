#!/bin/bash

# Daftar nama server yang ingin dicari
servers=("phoenix-hbase-lb" "node-nifi-hbase-3" "node-nifi-hbase-2" "hbase-worker-node-6" "Hbase-worker-node-5" "hbase-worker-node-4" "hbase-worker-node-3" "hbase-worker-node-2" "hbase-worker-node-1" "hbase-utility-node-1" "hbase-master-node-3" "hbase-master-node-2" "hbase-master-node-1")

for server in "${servers[@]}"; do
    # echo "Server: $server"

    # Cari server ID
    server_id=$(openstack server list --project edm --name "$server" -c ID -f value)

    if [ -z "$server_id" ]; then
        echo "Server tidak ditemukan."
    else
        # Dapatkan nilai host dari server
        host=$(openstack server show "$server_id" -c OS-EXT-SRV-ATTR:host -f value)
        echo "$host"
    fi

    # echo "--------------------------------------"
done
