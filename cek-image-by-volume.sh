#!/bin/bash

project_name="$1"

# Get the IDs of the servers in the ddb-staging project
server_ids=$(openstack server list --project $project_name -c ID -f value)

# Loop through the server IDs
for server_id in $server_ids; do
  # Get the volume attachments for the current server
  volume_ids=$(openstack server show $server_id -c volumes_attached -f value | awk -F "id='" '{print $2}' | awk -F "'" '{print $1}' | head -1)
  # Loop through the volume IDs
  for volume_id in $volume_ids; do
    # Get the image name for the current volume
    image_name=$(openstack volume show $volume_id -c volume_image_metadata -f value | awk -F "'image_name': '" '{print $2}' | awk -F "', '" '{print $1}')
    # echo "Volume $volume_id is attached to image $image_name"
    echo $image_name
  done
done
