#!/usr/bin/python

import json

logs = [ '172.16.9.39', '172.16.9.40' ,'172.16.9.79' ,'172.16.9.80' ]
l2 = []
for i in logs:
    l2.append({"{#REDIS_LOG}": i})

d1 = {'data':l2}
#print d1
data = json.dumps(d1)
print data
