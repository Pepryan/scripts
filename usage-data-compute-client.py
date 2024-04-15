import subprocess
import json

#for automation into google xls and pdf

def get_hypervisor_data():
    command = "openstack hypervisor list --long -c 'Hypervisor Hostname' -c 'Host IP' -c 'vCPUs Used' -c 'vCPUs' -c 'Memory MB Used' -c 'Memory MB' -f value"
    output = subprocess.getoutput(command)
    hypervisor_data = output.split('\n')
    return hypervisor_data

def extract_host_data(host_line):
    host_info = host_line.split()
    hostname = host_info[0]
    ip = host_info[1]
    vcpus_used = int(host_info[2])
    vcpus_total = int(host_info[3])
    memory_used = int(host_info[4])
    memory_total = int(host_info[5])
    cpu_ratio = get_host_cpu_ratio(hostname)
    ram_ratio = get_host_ram_ratio(hostname)
    adjusted_vcpus_total = calculate_total_vcpu(vcpus_total, cpu_ratio)
    adjusted_memory_total = calculate_total_ram(memory_total, ram_ratio)
    return hostname, ip, vcpus_used, adjusted_vcpus_total, memory_used, adjusted_memory_total

def is_host_dedicated(host_line):
    return get_host_cpu_ratio(host_line.split()[0]) == 1.0

def is_host_shared(host_line):
    return get_host_cpu_ratio(host_line.split()[0]) != 1.0

def get_host_cpu_ratio(host):
    command = f"ssh {host} sudo cat /etc/nova/nova.conf | grep -oP 'cpu_allocation_ratio = \K\d+(\.\d+)?'"
    output = subprocess.getoutput(command)
    return float(output) if output else 1.0

def get_host_ram_ratio(host):
    command = f"ssh {host} sudo cat /etc/nova/nova.conf | grep -oP 'ram_allocation_ratio = \K\d+(\.\d+)?'"
    output = subprocess.getoutput(command)
    return float(output) if output else 1.0

def calculate_total_vcpu(vcpus_total, ratio):
    return int(vcpus_total * ratio)

def calculate_total_ram(memory_total, ratio):
    return int(memory_total * ratio)

def calculate_vcpu_usage(vcpus_used, vcpus_total):
    return round((vcpus_used / vcpus_total) * 100, 2) if vcpus_total > 0 else 0

def calculate_ram_usage(memory_used, memory_total):
    return round((memory_used / memory_total) * 100, 2) if memory_total > 0 else 0

def get_host_cpu_utilization(hostname):
    command = f"ssh {hostname} top -bn1 | grep load | awk '{{printf \"%2.2f%%\\n\", $(NF-2)}}'"
    output = subprocess.getoutput(command)
    return output

def get_host_memory_utilization(hostname):
    command = f"ssh {hostname} free -m | awk 'NR==2{{printf \"%2.2f%%\\n\", $3*100/$2 }}'"
    output = subprocess.getoutput(command)
    return output

def get_host_disk_utilization(hostname):
    command = f"ssh {hostname} df -h | awk '$NF==\"/\"{{printf \"%s\\n\", $5}}'"
    output = subprocess.getoutput(command)
    return output

def main():
    # Source OpenStack admin credentials
    # subprocess.run("source ~/admin-openrc", shell=True, check=True)

    hypervisor_data = get_hypervisor_data()
    dedicated_hosts_data = []
    shared_hosts_data = []
    
    for line in hypervisor_data:
        if is_host_dedicated(line):
            dedicated_hosts_data.append(extract_host_data(line))
        elif is_host_shared(line):
            shared_hosts_data.append(extract_host_data(line))

    # Sort data based on IP
    dedicated_hosts_data.sort(key=lambda x: x[1])
    shared_hosts_data.sort(key=lambda x: x[1])
    
    # Print current output for dedicated hosts
    print("Dedicated Hosts:")
    for data in dedicated_hosts_data:
        cpu_utilization = get_host_cpu_utilization(data[0])
        memory_utilization = get_host_memory_utilization(data[0])
        disk_utilization = get_host_disk_utilization(data[0])
        vcpu_usage_percent = calculate_vcpu_usage(data[2], data[3])
        ram_usage_percent = calculate_ram_usage(data[4], data[5])
        # print(f"{data[0]}, {data[1]}, {data[2]}/{data[3]}, {data[4]}/{data[5]} MB, CPU Utilization: {cpu_utilization}, Memory Utilization: {memory_utilization}, Disk Utilization: {disk_utilization}")
        print(f"{data[0]}, {data[1]}, up, {vcpu_usage_percent}%, {ram_usage_percent}%, {cpu_utilization}, {memory_utilization}, {disk_utilization}")

    # Print current output for shared hosts
    print("\nShared Hosts:")
    for data in shared_hosts_data:
        cpu_utilization = get_host_cpu_utilization(data[0])
        memory_utilization = get_host_memory_utilization(data[0])
        disk_utilization = get_host_disk_utilization(data[0])
        vcpu_usage_percent = calculate_vcpu_usage(data[2], data[3])
        ram_usage_percent = calculate_ram_usage(data[4], data[5])
        # print(f"{data[0]}, {data[1]}, {data[2]}/{data[3]}, {data[4]}/{data[5]} MB, CPU Utilization: {cpu_utilization}, Memory Utilization: {memory_utilization}, Disk Utilization: {disk_utilization}")
        print(f"{data[0]}, {data[1]}, up, {vcpu_usage_percent}%, {ram_usage_percent}%, {cpu_utilization}, {memory_utilization}, {disk_utilization}")

    # # Prepare data for JSON output
    # dedicated_names = [[name[0]] for name in dedicated_hosts_data]
    # shared_names = [[name[0]] for name in shared_hosts_data]
    # dedicated_ips = [[ip[1]] for ip in dedicated_hosts_data]
    # shared_ips = [[ip[1]] for ip in shared_hosts_data]
    # dedicated_vcpu_usage = [[calculate_vcpu_usage(data[2], data[3])] for data in dedicated_hosts_data]
    # shared_vcpu_usage = [[calculate_vcpu_usage(data[2], data[3])] for data in shared_hosts_data]
    # dedicated_ram_usage = [[calculate_ram_usage(data[4], data[5])] for data in dedicated_hosts_data]
    # shared_ram_usage = [[calculate_ram_usage(data[4], data[5])] for data in shared_hosts_data]
    # dedicated_cpu_utilization = [[get_host_cpu_utilization(data[0])] for data in dedicated_hosts_data]
    # dedicated_memory_utilization = [[get_host_memory_utilization(data[0])] for data in dedicated_hosts_data]
    # dedicated_disk_utilization = [[get_host_disk_utilization(data[0])] for data in dedicated_hosts_data]
    # shared_cpu_utilization = [[get_host_cpu_utilization(data[0])] for data in shared_hosts_data]
    # shared_memory_utilization = [[get_host_memory_utilization(data[0])] for data in shared_hosts_data]
    # shared_disk_utilization = [[get_host_disk_utilization(data[0])] for data in shared_hosts_data]
    
    # # Construct JSON output
    # json_output = [
    #     {"A5:A18": dedicated_names}, {"B5:B18": dedicated_ips}, {"D5:D18": dedicated_vcpu_usage}, {"E5:E18": dedicated_ram_usage}, {"F5:F18": dedicated_cpu_utilization}, {"G5:G18": dedicated_memory_utilization}, {"H5:H18": dedicated_disk_utilization},
    #     {"J5:J57": shared_names}, {"K5:K57": shared_ips}, {"M5:M57": shared_vcpu_usage}, {"N5:N57": shared_ram_usage},{"O5:O57": shared_cpu_utilization}, {"P5:P57": shared_memory_utilization}, {"Q5:Q57": shared_disk_utilization}
    # ]
    # print("\nJSON Output:")
    # print(json.dumps(json_output))

if __name__ == "__main__":
    main()
