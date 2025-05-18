#!/bin/bash
#
# NFS metrics collector for Node Exporter textfile collector
# Save this file as /usr/local/bin/nfs_textfile_collector.sh and make it executable
# chmod +x /usr/local/bin/nfs_textfile_collector.sh
#
# Create a cron job to run this script periodically:
# */5 * * * * /usr/local/bin/nfs_textfile_collector.sh

# Set the output directory - this should match your Node Exporter textfile collector directory
TEXTFILE_COLLECTOR_DIR="/var/lib/node_exporter/textfile_collector"

# Make sure the directory exists
mkdir -p "${TEXTFILE_COLLECTOR_DIR}"

# Temporary file to build metrics
TEMP_FILE=$(mktemp)

# Function to handle timeout
handle_timeout() {
  echo "# HELP nfs_collector_status Indicates if the NFS collector script completed successfully"
  echo "# TYPE nfs_collector_status gauge"
  echo "nfs_collector_status 0"
  echo "# HELP nfs_collector_error_info Information about the collector error"
  echo "# TYPE nfs_collector_error_info gauge"
  echo "nfs_collector_error_info{error=\"timeout\"} 1"
}

# Set a timeout for the script (30 seconds)
TIMEOUT=30

# Create a timer to monitor execution time
(
  sleep $TIMEOUT
  echo "Script timed out after $TIMEOUT seconds" >&2
  # Output timeout metrics to the temp file
  handle_timeout > "$TEMP_FILE"
  mv "$TEMP_FILE" "${TEXTFILE_COLLECTOR_DIR}/nfs_metrics.prom"
  exit 0
) &
TIMER_PID=$!

# Function to clean up the timer when done
cleanup() {
  kill $TIMER_PID 2>/dev/null
}
trap cleanup EXIT

# Header for metrics file
cat > "$TEMP_FILE" << EOF
# HELP nfs_collector_status Indicates if the NFS collector script completed successfully
# TYPE nfs_collector_status gauge
nfs_collector_status 1

# HELP node_nfs_mount_state NFS mount state (1=mounted, 0=not mounted)
# TYPE node_nfs_mount_state gauge
EOF

# Check NFS mounts
while read -r mount_point fstype options rest; do
  if [[ "$fstype" == "nfs" || "$fstype" == "nfs4" ]]; then
    # Check if mount is responsive with a quick timeout
    if timeout 2 stat -f "$mount_point" > /dev/null 2>&1; then
      echo "node_nfs_mount_state{mountpoint=\"$mount_point\",type=\"$fstype\"} 1" >> "$TEMP_FILE"
    else
      echo "node_nfs_mount_state{mountpoint=\"$mount_point\",type=\"$fstype\"} 0" >> "$TEMP_FILE"
    fi
  fi
done < /proc/mounts

# Add filesystem size metrics similar to node_filesystem_size_bytes
echo -e "\n# HELP node_filesystem_size_bytes Filesystem size in bytes" >> "$TEMP_FILE"
echo "# TYPE node_filesystem_size_bytes gauge" >> "$TEMP_FILE"
echo -e "\n# HELP node_filesystem_avail_bytes Filesystem space available in bytes" >> "$TEMP_FILE"
echo "# TYPE node_filesystem_avail_bytes gauge" >> "$TEMP_FILE"
echo -e "\n# HELP node_filesystem_free_bytes Filesystem free space in bytes" >> "$TEMP_FILE"
echo "# TYPE node_filesystem_free_bytes gauge" >> "$TEMP_FILE"

# Get filesystem sizes for NFS mounts
while read -r device mountpoint fstype options rest; do
  if [[ "$fstype" == "nfs" || "$fstype" == "nfs4" ]]; then
    # Use timeout to prevent hanging
    if SIZE_INFO=$(timeout 5 df -B1 --output=size,avail,itotal,iavail "$mountpoint" 2>/dev/null); then
      # Parse the output
      SIZE=$(echo "$SIZE_INFO" | tail -n1 | awk '{print $1}')
      AVAIL=$(echo "$SIZE_INFO" | tail -n1 | awk '{print $2}')
      FREE=$AVAIL  # For consistency with node_exporter
      
      # Output the metrics with the same labels as node_exporter would
      echo "node_filesystem_size_bytes{device=\"$device\",fstype=\"$fstype\",mountpoint=\"$mountpoint\"} $SIZE" >> "$TEMP_FILE"
      echo "node_filesystem_avail_bytes{device=\"$device\",fstype=\"$fstype\",mountpoint=\"$mountpoint\"} $AVAIL" >> "$TEMP_FILE"
      echo "node_filesystem_free_bytes{device=\"$device\",fstype=\"$fstype\",mountpoint=\"$mountpoint\"} $FREE" >> "$TEMP_FILE"
    else
      # If df command times out, use fallback values that won't trigger alerts but still show the mount exists
      echo "node_filesystem_size_bytes{device=\"$device\",fstype=\"$fstype\",mountpoint=\"$mountpoint\"} -1" >> "$TEMP_FILE"
      echo "node_filesystem_avail_bytes{device=\"$device\",fstype=\"$fstype\",mountpoint=\"$mountpoint\"} -1" >> "$TEMP_FILE"
      echo "node_filesystem_free_bytes{device=\"$device\",fstype=\"$fstype\",mountpoint=\"$mountpoint\"} -1" >> "$TEMP_FILE"
    fi
  fi
done < /proc/mounts

# Extract NFS operation metrics if available
if [ -f /proc/self/mountstats ]; then
  echo -e "\n# HELP node_nfs_operations_total Total number of NFS operations by type and mount point" >> "$TEMP_FILE"
  echo "# TYPE node_nfs_operations_total counter" >> "$TEMP_FILE"
  
  # Process the mountstats file in a controlled manner
  timeout 10 awk '
  BEGIN { mount = ""; }
  /^device / { mount = $2; }
  /^[[:space:]]+[[:alpha:]]+ +[0-9]+ +[0-9]+ +[0-9]+ +[0-9]+ +[0-9]+ +[0-9]+ +[0-9]+ +[0-9]+/ {
    if (mount != "") {
      operation = $1
      calls = $2
      print "node_nfs_operations_total{mountpoint=\"" mount "\",operation=\"" operation "\"} " calls
    }
  }
  ' /proc/self/mountstats >> "$TEMP_FILE" 2>/dev/null

  # NFS bytes read/written
  echo -e "\n# HELP node_nfs_bytes_read_total Total bytes read from NFS mounts" >> "$TEMP_FILE"
  echo "# TYPE node_nfs_bytes_read_total counter" >> "$TEMP_FILE"
  echo -e "\n# HELP node_nfs_bytes_written_total Total bytes written to NFS mounts" >> "$TEMP_FILE"
  echo "# TYPE node_nfs_bytes_written_total counter" >> "$TEMP_FILE"
  
  timeout 5 awk '
  BEGIN { mount = ""; }
  /^device / { mount = $2; }
  /bytes: / {
    if (mount != "") {
      split($0, arr, " ")
      for (i = 1; i <= length(arr); i++) {
        if (arr[i] == "read:") {
          print "node_nfs_bytes_read_total{mountpoint=\"" mount "\"} " arr[i+1]
        }
        if (arr[i] == "write:") {
          print "node_nfs_bytes_written_total{mountpoint=\"" mount "\"} " arr[i+1]
        }
      }
    }
  }
  ' /proc/self/mountstats >> "$TEMP_FILE" 2>/dev/null
fi

# NFS response time metrics
echo -e "\n# HELP node_nfs_rtt_milliseconds NFS round-trip time in milliseconds" >> "$TEMP_FILE"
echo "# TYPE node_nfs_rtt_milliseconds gauge" >> "$TEMP_FILE"

# Sample some NFS operations for RTT with strict timeout
for mount_point in $(awk '$3 == "nfs" || $3 == "nfs4" {print $2}' /proc/mounts); do
  # Try to get a quick response time measurement with timeout
  start_time=$(date +%s%N)
  if timeout 1 stat "$mount_point" > /dev/null 2>&1; then
    end_time=$(date +%s%N)
    # Calculate ms from ns
    rtt=$(( (end_time - start_time) / 1000000 ))
    echo "node_nfs_rtt_milliseconds{mountpoint=\"$mount_point\",operation=\"stat\"} $rtt" >> "$TEMP_FILE"
  else
    # If timeout, record as a high value
    echo "node_nfs_rtt_milliseconds{mountpoint=\"$mount_point\",operation=\"stat\"} 10000" >> "$TEMP_FILE"
  fi
done

# Move the temporary file to the final destination
mv "$TEMP_FILE" "${TEXTFILE_COLLECTOR_DIR}/nfs_metrics.prom"

# Kill the timer process as we've completed successfully
cleanup
exit 0
