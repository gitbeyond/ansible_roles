#!/usr/bin/python
# -*- encoding: utf8 -*-

import json

logs = {{fping_target_addrs | from_yaml}}
{%raw%}
#logs = [
#{"{#PUBADDR}": "210.82.6.1", "{#PUBNAME}": "Beijing Unicom"},
#]


l2 = []
for i in logs:
    item = {"{#TARGETADDR}": i['target_addr'], "{#TARGETDESC}": i['target_desc']}
    l2.append(item)

d1 = {'data':l2}
#print d1
data = json.dumps(d1)
#print json.dumps(d1).decode("unicode-escape")
print data
{%endraw%}
