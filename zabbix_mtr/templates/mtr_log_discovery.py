#!/usr/bin/python
# -*- encoding: utf8 -*-
# yum install mtr
# 针对 mtr 0.85 的输出的脚本
import json
import re

log_dir="{{mtr_out_dir}}"
zabbix_agent_script_dir="{{zabbix_agent_script_dir}}"

{%raw%}
mtr_log_splitter=","
def main():
    # 存储 host 列表
    fdata = []
    with open( zabbix_agent_script_dir + "/mtr_hosts.txt", 'r') as f:
        fdata = f.readlines()
    
    r1 = re.compile(r'^#|^$')
    l1 = []
    # check null and comment
    for i in fdata:
        # 将注释和空行筛选出去
        if r1.search(i) == None:
            l1.append(i)
    
    # 存储筛选过后的数据
    host_data = []
    # split by '\t' for per line
    # api-nginx-vip,172.21.50.126,icmp,443
    # api-nginx-vip,172.21.50.126,tcp,443
    host_data = [i.strip('\n').split(",") for i in l1]
    # 存储筛选出来的 host 数据
    l2 = []
    # 存储从文件中读到数据
    mtr_icmp_data = []
    for host in host_data:
        host_ip = host[1]
        host_type = host[2]
        host_port = host[3]
        if host_type == "icmp":
            mtr_log_file= '%s/%s_icmp.out' % (log_dir, host_ip)
        else:
            mtr_log_file= '%s/%s_tcp_%s.out' % (log_dir, host_ip, host_port)
        #
        with open(mtr_log_file, 'r') as mtr_icmp:
            # 各个版本的 mtr 生成的数据略有不同，需要根据实际情况，修改这里的语句
            # 这里删除第一行的原因，是因为其形式是 csv, 所以要删除第一行的字段名称
            mtr_icmp_data = mtr_icmp.readlines()[1:]
        # 删除其中的 ip 异常的 hop
        #mtr_icmp_data = filter(lambda: line: line.split(mtr_log_spli)[6] != "???", mtr_icmp_data)
        for hop_host in mtr_icmp_data:
            l2.append( { "{#HOPHOST}":  host_ip + '_' + hop_host.split(mtr_log_splitter)[4], 
                 "{#CHECK_HOST}": hop_host.split(mtr_log_splitter)[5],
                 "{#CHECK_TYPE}": host_type, "{#CHECK_PORT}": host_port  })
    #
    #dict_data = [ {"{#HOPHOST}":i} for i in l2 ]
    # 去重
    d1 = {'data': l2}
    data = json.dumps(d1)
    print(data)
#
if __name__ == '__main__':
    main()
{%endraw%}
