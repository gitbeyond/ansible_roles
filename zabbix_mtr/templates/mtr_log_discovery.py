#!/usr/bin/python
# -*- encoding: utf8 -*-
import json
import re

with open("{{zabbix_agent_script_dir}}/mtr_hosts.txt") as f:
    fdata = f.readlines()

r1 = re.compile(r'^#|^$')
l1 = []
# check null and comment
for i in fdata:
    if r1.search(i) == None:
        l1.append(i)

fdata = l1
# split by '\t' for per line
#fdata = [i.strip('\n').split('\t') for i in fdata]
fdata = [i.strip('\n').split(',')[1] for i in fdata]

fdata = set(fdata)
#for i in fdata:
#    i[1] = i[1].split('/')[2].strip(' ')
l2 = []
for host in fdata:
    mtr_icmp_out_file= '/tmp/.' + host + '_icmp.out'
    with open(mtr_icmp_out_file, 'r') as mtr_icmp:
        mtr_icmp_data = mtr_icmp.readlines()[1:]
    for hop_host in mtr_icmp_data:
        l2.append(host + '_' +hop_host.split(',')[5])
         

fdata = [ {"{%raw%}{#HOPHOST}{%endraw%}":i} for i in l2 ]

d1 = {'data': fdata}
data = json.dumps(d1)
print data
