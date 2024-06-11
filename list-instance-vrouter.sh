#!/bin/bash

# IP Gateway yang ingin dicari
TARGET_IP="172.18.216.193"

# Ambil ID router yang sesuai dengan TARGET_IP
ROUTER_ID=$(openstack router list --long | grep $TARGET_IP | awk '{print $2}')

if [ -z "$ROUTER_ID" ]; then
  echo "Router dengan IP $TARGET_IP tidak ditemukan."
  exit 1
fi

# Ambil informasi interface dari router
INTERFACES=$(openstack router show $ROUTER_ID -c interfaces_info -f json)

# Parse JSON untuk mendapatkan IP address
IP_ADDRESSES=$(echo $INTERFACES | jq -r '.interfaces_info[].ip_address')

for IP in $IP_ADDRESSES; do
  # Ambil tiga oktet pertama dari IP address
  OCTETS=$(echo $IP | awk -F. '{print $1"."$2"."$3}')
  
  # Cari instance dengan tiga oktet pertama yang sesuai
  #echo "Mencari instance dengan tiga oktet pertama: $OCTETS"
  openstack server list --all-projects --long -f csv | grep $OCTETS
done
