#!/bin/bash

#for hypervisor utilization data per month usually requested by mba nisy 

# Function to get hypervisor data
get_hypervisor_data() {
  openstack hypervisor list --long -c 'Hypervisor Hostname' -c 'Host IP' -c 'vCPUs Used' -c 'vCPUs' -c 'Memory MB Used' -c 'Memory MB' -f value
}

# Function to check if the host is dedicated based on CPU ratio
is_host_dedicated() {
  local hostname=$1
  local cpu_ratio=$(ssh "$hostname" "sudo cat /etc/nova/nova.conf | grep -oP 'cpu_allocation_ratio = \K\d+(\.\d+)?'")
  [[ "$cpu_ratio" == "1.0" ]]
}

# Function to extract host data, reorder for sorting
extract_and_print_host_data() {
  local line=$1
  local type=$2
  read hostname ip vcpus_used vcpus_total memory_used memory_total <<<$(echo $line)
  local cpu_ratio=$(ssh "$hostname" "sudo cat /etc/nova/nova.conf | grep -oP 'cpu_allocation_ratio = \K\d+(\.\d+)?'")
  local ram_ratio=$(ssh "$hostname" "sudo cat /etc/nova/nova.conf | grep -oP 'ram_allocation_ratio = \K\d+(\.\d+)?'")
  local adjusted_vcpus_total=$(awk "BEGIN {print int($vcpus_total * $cpu_ratio)}")
  local adjusted_memory_total=$(awk "BEGIN {print int($memory_total * $ram_ratio)}")
  local vcpu_usage_percent=$(awk "BEGIN {printf \"%0.2f\", (($vcpus_used / $adjusted_vcpus_total) * 100)}")
  local ram_usage_percent=$(awk "BEGIN {printf \"%0.2f\", (($memory_used / $adjusted_memory_total) * 100)}")
  local cpu_utilization=$(ssh "$hostname" "top -bn1 | grep load | awk '{printf \"%2.2f%%\\n\", \$(NF-2)}'")
  local memory_utilization=$(ssh "$hostname" "free -m | awk 'NR==2{printf \"%2.2f%%\\n\", \$3*100/\$2 }'")
  local disk_utilization=$(ssh "$hostname" "df -h | awk '\$NF==\"/\"{printf \"%s\\n\", \$5}'")

  # Append IP for sorting but print in original order
  echo "$ip, $hostname, $ip, up, $vcpu_usage_percent%, $ram_usage_percent%, $cpu_utilization, $memory_utilization, $disk_utilization" >> "${type}_hosts_temp.txt"
}

# Source OpenStack admin credentials
source ~/admin-openrc

# Get hypervisor data
mapfile -t hypervisor_data < <(get_hypervisor_data)

# Process each hypervisor line
for line in "${hypervisor_data[@]}"; do
  hostname=$(echo $line | awk '{print $1}')
  if is_host_dedicated "$hostname"; then
    extract_and_print_host_data "$line" "dedicated"
  else
    extract_and_print_host_data "$line" "shared"
  fi
done

# Sort by IP, then remove the sorting key column
echo "Dedicated Hosts:" > dedicated_hosts.txt
sort -t, -k1,1 dedicated_hosts_temp.txt | cut -d, -f2- >> dedicated_hosts.txt
echo "Shared Hosts:" > shared_hosts.txt
sort -t, -k1,1 shared_hosts_temp.txt | cut -d, -f2- >> shared_hosts.txt

# Display output
cat dedicated_hosts.txt
cat shared_hosts.txt

# Cleanup temporary files
rm *_hosts_temp.txt
