#!/bin/bash
source ~/admin-openrc

list_id=$(openstack floating ip list -c ID -f value)

while IFS= read -r line; do
  id=$line
  floating_info=$(openstack floating ip show $id -f json)
  #admin_state=$(echo $floating_info | jq -r '.admin_state_up')
  port_id=$(echo $floating_info | jq -r '.port_id')
  #device_id=$(echo $floating_info | jq -r '.device_id')
  #device_owner=$(echo $floating_info | jq -r '.device_owner')
  fixed_ips=$(echo $floating_info | jq -r '.fixed_ip_address')
  floating_ips=$(echo $floating_info | jq -r '.floating_ip_address')
  floating_id=$(echo $floating_info | jq -r '.id')
  #mac_address=$(echo $floating_info | jq -r '.mac_address')
  name=$(echo $floating_info | jq -r '.name')
  project_id=$(echo $floating_info | jq -r '.project_id')
  project=$(openstack project show $project_id -c name -f value)
  status=$(echo $floating_info | jq -r '.status')
  tags=$(echo $floating_info | jq -r '.tags')
  #secgroup=$(echo $floating_info | jq -r '.security_group_ids'| jq -c .)
  if [[ "$port_id" = "null" ]]; then
    echo "$floating_id,$name,$floating_ips,$fixed_ips,$status,$port_id,$tags,$project"
  fi
done <<< "$list_id"
