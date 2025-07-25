#!/bin/bash

#cek security group by id_port file (id port)
id_port=$@
for i in `cat $id_port`
do
#echo $i
openstack port show $i -c security_group_ids -f value | sed 's/^..//;s/..$//'
done
