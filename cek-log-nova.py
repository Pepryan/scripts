#!/usr/bin/env python3
import os

# Baca daftar hostname server dari file teks
with open('compute.txt', 'r') as file:
    daftar_server = file.readlines()

daftar_server = [server.strip() for server in daftar_server]

for server in daftar_server:
    print(f"Memeriksa log Nova ERROR pada server {server}...")

    perintah = f"ssh {server} 'cat /var/log/nova/nova-compute.log | cat /var/log/nova/nova-compute.log.1 | zcat /var/log/nova/nova-compute.log.2.gz |zcat /var/log/nova/nova-compute.log.3.gz|zcat /var/log/nova/nova-compute.log.4.gz | grep ERROR'"
    output = os.popen(perintah).read()

    if output:
        print(f"Error pada server {server}:\n{output}")
    else:
        print(f"Tidak ada ERROR pada server {server}")
    
    print() 
