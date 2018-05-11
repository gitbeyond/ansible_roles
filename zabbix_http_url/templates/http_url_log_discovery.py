#!/usr/bin/python
# -*- encoding: utf8 -*-
import json
import re

with open("{{/usr/local/zabbix/script}}/http_url.txt") as f:
    fdata = f.readlines()

r1 = re.compile(r'^#|^$')
l1 = []
# 检测空行和注释
for i in fdata:
    if r1.search(i) == None:
        l1.append(i)

fdata = l1
print len(fdata)
# 将每行按制表符分割
fdata = [i.strip('\n').split('\t') for i in fdata]

# 如果不能按制表符分割的行，则按空格分割
for i in range(len(fdata)):
    if len(fdata[i])==1:
        fdata[i] = fdata[i][0].split()

# 再次检测异常的行，如果有，将其删除
l2 = []
for i in range(len(fdata)):
    if len(fdata[i]) == 2:
        l2.append(fdata[i])

fdata = l2

for i in fdata:
    i[1] = i[1].split('/')[2].strip(' ')


fdata = [ {"{%raw%}{#DSCODE}{%endraw%}":i[0], "{%raw%}{#DSADDR}{%endraw%}": i[1]} for i in fdata ]
print len(fdata)

d1 = {'data': fdata}
data = json.dumps(d1)
print data

