#!/bin/bash          

ip_file="ip.txt"
username="tshoot"
users=(ubuntu centos cloud-user)

reconfigure_passwd() {
    user=$1    
         
    ssh -i ~/devops.pem -l $user -o "ConnectTimeout=10" -o "GSSAPIAuthentication=no" -o "PasswordAuthentication=no" -o "StrictHostKeychecking=no" $ip "echo 'FzX3sdmbvaKR01HE' | su - tshoot -c 'whoami;echo FzX3sdmbvaKR01HE| sudo -S whoami'" 2&>1 > /dev/null
    if [ "$?" -eq 0 ]; then
        echo "$ip, DONE: password $username reconfigured"
    else
        echo "$ip, ISSUE: $username not in sudoers file, or another issue, error code $?"
    fi
}

adding_tshoot() {
    user=$1
    group="sudo"

    if [ "$user" == "cloud-user" ] || [ "$user" == "centos" ]; then
        group="wheel"
    fi

    ssh -i ~/devops.pem -l $user -o "ConnectTimeout=10" -o "GSSAPIAuthentication=no" -o "PasswordAuthentication=no" -o "StrictHostKeychecking=no" $ip "sudo useradd -M tshoot -e -1 -c 'Btech Troubleshooting Account' -G $group" 2> /dev/null
    if [ "$?" -eq 0 ]; then 
        echo -n "$ip, DONE: adding $username user;"
    else 
        echo -n "$ip, ISSUE: failed to add $username, error code $?;"
    fi

    ssh -i ~/devops.pem -l $user -o "ConnectTimeout=10" -o "GSSAPIAuthentication=no" -o "PasswordAuthentication=no" -o "StrictHostKeychecking=no" $ip "echo '$username:FzX3sdmbvaKR01HE' | sudo chpasswd" 2> /dev/null
    if [ "$?" -eq 0 ]; then 
        echo "DONE: adding $username password"
    else 
        echo "$ip, ISSUE: failed to change $username password, error code $?"
    fi
}

for ip in $(cat "$ip_file"); do
    for user in "${users[@]}"; do
        ssh -q -i ~/devops.pem -l $user -o "ConnectTimeout=10" -o "GSSAPIAuthentication=no" -o "PasswordAuthentication=no" -o "StrictHostKeychecking=no" $ip exit >/dev/null

        if [ "$?" -eq 0 ]; then
            tshoot_exist=$(ssh -i ~/devops.pem -l $user -o "ConnectTimeout=10" -o "GSSAPIAuthentication=no" -o "PasswordAuthentication=no" -o "StrictHostKeychecking=no" $ip "cat /etc/passwd | grep $username" 2> /dev/null)

            if [ -n "$tshoot_exist" ]; then
                reconfigure_passwd "$user"
                break
            else
                adding_tshoot "$user"
                break
            fi

        else
            if [ "$user" != "cloud-user" ]; then
                continue
            else
                echo "$ip, ISSUE: can't ssh to instances, move to next IP"
                break
            fi
        fi

    done
done

echo -e "\n"
