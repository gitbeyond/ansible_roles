#!/usr/bin/python
# -*- encoding: utf8 -*-

import json

logs = [
{"{#PUBADDR}": "210.82.6.1", "{#PUBNAME}": "Beijing Unicom"},
{"{#PUBADDR}": "219.158.6.162", "{#PUBNAME}": "Shanghai Unicom"},
{"{#PUBADDR}": "163.179.0.1", "{#PUBNAME}": "Guangdong Unicom"},
{"{#PUBADDR}": "61.49.43.185", "{#PUBNAME}": "Beijing Telecom"},
#{"{#PUBADDR}": "218.1.23.142", "{#PUBNAME}": "Shanghai Telecom"},
{"{#PUBADDR}": "101.95.120.113", "{#PUBNAME}": "Shanghai Telecom"},
{"{#PUBADDR}": "219.135.131.210", "{#PUBNAME}": "Guangdong Telecom"},
]
l2 = []
for i in logs:
    l2.append(i)

d1 = {'data':l2}
#print d1
data = json.dumps(d1)
#print json.dumps(d1).decode("unicode-escape")
print data

