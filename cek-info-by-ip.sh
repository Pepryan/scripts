#!/bin/bash

# Project
project_name=$1

# Daftar IP
ip_list=($(cat ip.txt))

# LoopIP
for ip in "${ip_list[@]}"
do
    instance_info=$(openstack server show $(openstack server list --project $project_name --ip "$ip" -f value -c ID) -f json)

    instance_id=$(echo "$instance_info" | jq -r '.id')
    instance_name=$(echo "$instance_info" | jq -r '.name')
    floating_ip=$(echo "$instance_info" | jq -r '.addresses | split(", ")[1]')
    # floating_ip=$(echo "$instance_info" | jq -r '.addresses | split(", ")[1]' | awk -F'=' '{print $2}')
    # external_ip=$(echo "$instance_info" | jq -r '.addresses | split(", ")[2]' | awk -F'=' '{print $2}')
    
    flavor_id=$(echo "$instance_info" | jq -r '.flavor' | awk -F' ' '{print $1}')
    
    flavor_info=$(openstack flavor show "$flavor_id" -f json)
    
    # Parsing informasi RAM dan vCPU dari flavor
    ram=$(echo "$flavor_info" | jq -r '.ram')
    ram_gb=$((ram/1024))
    vcpus=$(echo "$flavor_info" | jq -r '.vcpus')

    # Output
    # echo "IP $ip, Instance ID $instance_id, Instance Name $instance_name, Floating IP $floating_ip, $vcpus, $ram_gb"
    echo $ip, $instance_id, $instance_name, $floating_ip, $vcpus, $ram_gb"G"
    # echo "External IP: $external_ip"
    # echo ""
    # echo "IP: $ip, Instance ID: $instance_id"
done
