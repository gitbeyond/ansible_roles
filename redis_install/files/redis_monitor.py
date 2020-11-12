#!/usr/bin/env python
#-*- coding:utf-8 -*-

import redis
import sys

r = redis.Redis(host='172.16.8.161',port=6379,db=0)

pool = redis.ConnectionPool(max_connections=1,host='127.0.0.1',port=6379)
r = redis.Redis(connection_pool=pool)


data=r.info()
arg1=sys.argv[1]
print data[arg1]
#print pool.get_connection('info')
#print pool.release(r)

pool.disconnect()
#redis_hosts = ['172.16.9.39', '172.16.9.40']
#
#def redis_info(conn_list, log_file, pt=6379):
#    savedStdout = sys.stdout
#    pool = redis.ConnectionPool(max_connections=1,host=conn_list,port=pt)
#    r = redis.Redis(connection_pool=pool)
#    data=r.info()
#    with open('/tmp/'+log_file,'w+') as file1:
#        sys.stdout = file1
#        print data
#    sys.stdout = savedStdout
#    pool.disconnect()
#
#redis_info('127.0.0.1','127.0.0.1_redis')
#
#for i in redis_hosts:
#    redis_info(i, i+'_redis')
