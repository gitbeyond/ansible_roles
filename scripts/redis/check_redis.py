#!/usr/bin/python
# yum install python2-redis on centos7

import sys
import redis

redis_host=sys.argv[1]
redis_port=sys.argv[2]
redis_pass=sys.argv[3]
redis_db=0

redis_cli = redis.Redis(host=redis_host, port=redis_port, password=redis_pass, db=redis_db,socket_connect_timeout=0.8)

try:
    redis_cli.ping()
except Exception as e:
    print "redis connection timeout",e
    sys.exit(1)

repl_info= redis_cli.info('replication')

#print repl_info
if repl_info.has_key('role'):
    if repl_info['role'] == "master":
        pass
    else:
        sys.exit(2)
else:
    sys.exit(3)
