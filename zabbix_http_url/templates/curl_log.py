#!/usr/bin/python
# -*- coding: utf-8 -*-

import sys

fname='{{curl_out_dir}}/'+sys.argv[1]
with open(fname, 'r') as f:
    off = -50
    while True:
        f.seek(off, 2)
        lines = f.readlines()
        if len(lines) >= 2:
            last_line = lines[-1]
            break
        off *= 2


state=sys.argv[2]
l1=['httpd_code', 'conn_time', 'trans_time', 'total_time', 'nslook_time']
print last_line.split(':')[l1.index(state)]
