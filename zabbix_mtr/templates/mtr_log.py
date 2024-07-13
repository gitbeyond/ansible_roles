#!/usr/bin/python
# -*- coding: utf-8 -*-
# yum install mtr
# 针对 mtr 0.85 的输出的脚本
import sys
log_dir="{{mtr_out_dir}}"

{%raw%}
host_hop_host=sys.argv[1]
state=sys.argv[2]
# icmp or tcp
check_type=sys.argv[3]

check_port=0
if len(sys.argv) > 4:
    check_port=sys.argv[4]

host = host_hop_host.split('_')[0]
#hop_host = host_hop_host.split('_')[1]
hop_number = host_hop_host.split('_')[1]

fname=""
if check_type == "icmp":
    #fname = log_dir + '/' + host + '_icmp.out'
    fname = "%s/%s_icmp.out" % (log_dir, host)
else:
    fname = "%s/%s_tcp_%s.out" % (log_dir, host, check_port)

mtr_log_splitter=","


"""
[root@P-None-3-204 ~]# /data/apps/opt/mtr/sbin/mtr -4 -n --tcp --port 80 -r -b -w -C 192.168.99.182 
Mtr_Version,Start_Time,Status,Host,Hop,Ip,Loss%,Snt, ,Last,Avg,Best,Wrst,StDev,
MTR.0.94,1620460381,OK,192.168.99.182,1,172.16.2.2,0.00,10,0,0.47,0.46,0.41,0.57,0.05

[root@P-None-3-204 ~]# /data/apps/opt/mtr/sbin/mtr -4 -n --tcp --report 192.168.99.182 --port 80
Start: 2021-05-08T13:47:51+0800
HOST: P-None-3-204                Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- 172.16.2.2                 0.0%    10    0.5   0.5   0.5   0.6   0.0
  2.|-- 10.10.10.10              0.0%    10    0.3   0.3   0.3   0.4   0.0
  3.|-- 10.8.253.70                0.0%    10    5.8   9.3   5.8  11.8   2.1
  4.|-- 10.6.1.9                   0.0%    10    4.9   7.4   4.9  12.8   2.4
  5.|-- 10.6.1.26                  0.0%    10    4.3   4.9   4.1  10.1   1.9
  6.|-- 192.168.99.182             0.0%    10    5.6   8.9   5.6  12.1   1.9

[root@P-None-3-204 ~]# /data/apps/opt/mtr/sbin/mtr -4 -n -c 1 -r -b -w -C 192.168.99.182 
Mtr_Version,Start_Time,Status,Host,Hop,Ip,Loss%,Snt, ,Last,Avg,Best,Wrst,StDev,
MTR.0.94,1620452113,OK,192.168.99.182,1,172.16.2.2,0.00,1,0,0.48,0.48,0.48,0.48,0.00
"""
def main():
    # 存储文件行数据
    lines = []
    # 存储筛选到的数据
    host_lines = []
    # 筛选到的单行数据
    last_line = []
    with open(fname, 'r') as f:
        lines = f.readlines()
        host_lines = filter(lambda line: line.split(mtr_log_splitter)[4] == hop_number, lines)
    
    # 这里有可能出现多个相同节点的情况
    if len(host_lines) >= 1:
        last_line = host_lines[0].split(mtr_log_splitter)
    else:
        print("the %s is error" % host_lines)
        return
    
    l1=['version','start_time', 'status', 
        'host', 'hop', 'ip', 'loss', 'snt',
        'empty', 'last', 'avg', 'best', 
        'wrst', 'stdev']
    if state == 'status':
        if last_line[l1.index(state)] == 'OK':
            print(1)
        else:
            print(0)
    else:
        print(last_line[l1.index(state)])

#
if __name__ == '__main__':
    main()
{%endraw%}
