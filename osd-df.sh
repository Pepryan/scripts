#!/usr/bin/env bash

#Script untuk ambil data buat lampiran di laporan bulanan
#Lampiran - Preventive Maintenance OpenStack GTI & ODC
#ambil data terus bisa diakalin di excel pake sorting
#merge same value: https://www.exceldemy.com/excel-merge-rows-with-same-value/

for host in `cat compute.txt`
do
ceph osd df tree $host|grep "hdd\|ssd"|awk -v host="$host" '{printf "%s,%s,%s,%s %s,%s %s,%s %s,%s %s,%s,%s,%s\n",$1,host,$2,$5,$6,$7,$8,$9,$10,$15,$16,$17,$19,$20}'|tr -d " "
done
