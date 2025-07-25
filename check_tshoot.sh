#!/bin/bash

# Output CSV file
OUTPUT_FILE="tshoot_results.csv"

# SSH options
SSH_OPTIONS="-o ConnectTimeout=10 -o GSSAPIAuthentication=no -o PasswordAuthentication=no -o StrictHostKeyChecking=no"

# Initialize CSV header
echo "ip,user_tshoot,keterangan" > "$OUTPUT_FILE"

# Create a temporary IP file without any potential issues
TMP_IP_FILE=$(mktemp)
grep -v "^$" ip.txt | tr -d '\r' > "$TMP_IP_FILE"

# Count total IPs
total_ips=$(wc -l < "$TMP_IP_FILE")
echo "Found $total_ips IPs to process"

# Process each IP one by one using a counter
counter=1

# Debug - show IP file content
# echo "First 5 IPs from file:"
# head -n 5 "$TMP_IP_FILE"

# Loop through each IP explicitly
for ip in $(cat "$TMP_IP_FILE"); do
    echo "[$counter/$total_ips] Checking IP: $ip"
    
    # Flag to indicate if we can SSH to the server
    ssh_success=false
    
    # Users to try
    users=("ubuntu" "cloud-user" "centos")
    
    # For each user
    for user in "${users[@]}"; do
        # Try without key first
        echo "  Trying $user without key..."
        ssh_output=$(ssh $SSH_OPTIONS "$user@$ip" "id tshoot 2>/dev/null || echo 'User tshoot not found'" 2>&1)
        ssh_status=$?
        
        # If SSH was successful
        if [ $ssh_status -eq 0 ]; then
            ssh_success=true
            
            # Check if tshoot user exists and get detailed info
            if [[ "$ssh_output" == *"uid="* && "$ssh_output" == *"tshoot"* ]]; then
                tshoot_details=$(echo "$ssh_output" | tr -d '\n' | sed 's/,/;/g')
                echo "$ip,\"FOUND: $tshoot_details\",Connected as $user without key" >> "$OUTPUT_FILE"
            else
                echo "$ip,\"NOT FOUND: User tshoot does not exist\",Connected as $user without key" >> "$OUTPUT_FILE"
            fi
            
            # Break the user loop since we found a working user
            break
        fi
        
        # Try with key
        echo "  Trying $user with key..."
        ssh_output=$(ssh $SSH_OPTIONS -i devops.pem "$user@$ip" "id tshoot 2>/dev/null || echo 'User tshoot not found'" 2>&1)
        ssh_status=$?
        
        # If SSH was successful
        if [ $ssh_status -eq 0 ]; then
            ssh_success=true
            
            # Check if tshoot user exists and get detailed info
            if [[ "$ssh_output" == *"uid="* && "$ssh_output" == *"tshoot"* ]]; then
                tshoot_details=$(echo "$ssh_output" | tr -d '\n' | sed 's/,/;/g')
                echo "$ip,\"FOUND: $tshoot_details\",Connected as $user with key" >> "$OUTPUT_FILE"
            else
                echo "$ip,\"NOT FOUND: User tshoot does not exist\",Connected as $user with key" >> "$OUTPUT_FILE"
            fi
            
            # Break the user loop since we found a working user
            break
        fi
    done
    
    # If no SSH connection was successful
    if [ "$ssh_success" = false ]; then
        echo "$ip,\"UNKNOWN: Cannot verify\",Cannot establish SSH connection with any user" >> "$OUTPUT_FILE"
    fi
    
    echo "-----------------------------------"
    # Increment counter
    ((counter++))
done

# Clean up
rm -f "$TMP_IP_FILE"

# Check how many IPs were actually processed
processed_ips=$(grep -v "^ip" "$OUTPUT_FILE" | wc -l)
echo "Script completed. Processed $processed_ips out of $total_ips IPs."
echo "Results saved to $OUTPUT_FILE"

# Show a sample of results
echo "Sample results:"
head -n 3 "$OUTPUT_FILE"