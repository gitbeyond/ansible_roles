#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin

osd_num=$1

ceph osd out ${osd_num}
systemctl stop ceph-osd@${osd_num}

ceph osd purge ${osd_num} --yes-i-really-mean-it

ceph osd crush remove osd.${osd_num}
ceph auth del osd.${osd_num}
ceph osd rm ${osd_num}

