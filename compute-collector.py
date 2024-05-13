import csv

def get_ip(networks):
    if networks:
        for net in networks.split(';'):
            parts = net.split('=')
            if len(parts) == 2:
                ip = parts[1]
                if ip.startswith('172.') or ip.startswith('10.') or ip.startswith('192.'):
                    return ip
        for net in networks.split(','):
            parts = net.split('=')
            if len(parts) == 2:
                ip = parts[1]
                if ip.startswith('172.') or ip.startswith('10.') or ip.startswith('192.'):
                    return ip
    return ""

def generate_metrics_from_csv(csv_file):
    metrics = ""
    with open(csv_file, newline='') as csvfile:
        reader = csv.DictReader(csvfile, delimiter='|')
        for row in reader:
            project = row['Project']
            name = row['Name']
            networks = row['Networks']
            host = row['Host']
            ip = get_ip(networks)
            metric = f"openstack_computes{{project=\"{project}\", name=\"{name}\", compute=\"{host}\", product_uuid=\"{row['ID']}\", ip=\"{ip}\"}} 1\n"
            metrics += metric
    return metrics

# Ubah "file.csv" dengan lokasi file CSV sesuai kebutuhan
metrics_data = generate_metrics_from_csv("aio.csv")

# Tulis data metrik ke dalam file .prom
with open("instance_metrics.prom", "w") as prom_file:
    prom_file.write(metrics_data)
