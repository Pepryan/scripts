#!/bin/bash

# List of server hostnames
servers=(
"compute-1"
"compute-2"
"compute-3"
"compute-4"
"compute-5"
"compute-6"
"compute-7"
"compute-8"
"compute-9"
"compute-10"
"compute-11"
"compute-12"
"compute-13"
"compute-14"
"compute-15"
"compute-16"
"compute-17"
"compute-18"
"compute-19"
"compute-20"
"compute-21"
"compute-22"
"compute-23"
"compute-24"
"compute-25"
"compute-26"
"compute-27"
"compute-28"
"compute-29"
"compute-30"
"compute-31"
"compute-32"
"compute-33"
"compute-34"
"compute-35"
"compute-36"
"compute-37"
"compute-38"
"compute-39"
"compute-40"
"compute-41"
"compute-42"
"compute-43"
"compute-44"
"compute-45"
"compute-46"
"compute-47"
"compute-48"
"compute-49"
"compute-50"
"compute-51"
"compute-52"
"compute-53"
"compute-54"
"compute-55"
"compute-56"
"compute-57"
"compute-58"
"compute-59"
"compute-60"
"compute-61"
"compute-62"
"compute-63"
"compute-64"
"compute-65"
"compute-66"
"compute-67"

)

# Loop through each server and run snap list command via SSH
for server in "${servers[@]}"; do
  echo "===== $server ====="
  ssh $server "snap list"
  echo ""
done
