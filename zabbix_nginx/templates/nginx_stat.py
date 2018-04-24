#!/usr/bin/python
# -*- coding:utf-8 -*-
import sys

fname='{{ zabbix_script_dir }}/nginx_status.txt'

with open(fname,'r') as f:
    data = f.readlines()

arg = sys.argv[1]

if arg == "connections":
    print data[0].split(' ')[2]
elif arg == "accepts":
    print data[2].split(' ')[1]
elif arg == "handled":
    print data[2].split(' ')[2]
elif arg == "requests":
    print data[2].split(' ')[3]
elif arg == "reading":
    print data[3].split(' ')[1]
elif arg == "writing":
    print data[3].split(' ')[3]
elif arg == "waiting":
    print data[3].split(' ')[5]
else:
    print "arg is error."
