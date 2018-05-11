#!/usr/bin/python
# -*- encoding: utf8 -*-
import json
import re

with open("{{zabbix_script_dir}}/http_url.txt") as f:
    fdata = f.readlines()

r1 = re.compile(r'^#|^$')
l1 = []
# check null and comment
for i in fdata:
    if r1.search(i) == None:
        l1.append(i)

fdata = l1
# split by '\t' for per line
fdata = [i.strip('\n').split('\t') for i in fdata]

# split by space for per line
for i in range(len(fdata)):
    if len(fdata[i])==1:
        fdata[i] = fdata[i][0].split()

# delete unusual
l2 = []
{%raw%}for i in range(len(fdata)):
    if len(fdata[i]) == 2:
        l2.append(fdata[i])
{%endraw%}
fdata = l2

for i in fdata:
    i[1] = i[1].split('/')[2].strip(' ')


fdata = [ {"{%raw%}{#DSCODE}{%endraw%}":i[0], "{%raw%}{#DSADDR}{%endraw%}": i[1]} for i in fdata ]

d1 = {'data': fdata}
data = json.dumps(d1)
print data
