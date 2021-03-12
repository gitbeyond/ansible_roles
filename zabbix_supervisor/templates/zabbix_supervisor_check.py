# -*- coding: utf-8 -*-
# editor: wanghaifeng@idstaff.com
# create date: 2021/03/01
# 通过 supervisor 的客户端获取 supervisor 的进程状态
# http://supervisord.org/api.html 
"""
# return list of all proc
zabbix_supervisor_check.py
# get app1 state
zabbix_supervisor_check.py app1 
# get supervisor state
zabbix_supervisor_check.py self_check
"""


import sys
import json

supervisor_rpc_address = 'http://{{supervisor_http_host}}:{{supervisor_http_port}}/RPC2'
supervisor_rpc_user = '{{supervisor_http_user}}'
supervisor_rpc_pass = '{{supervisor_http_pass}}'
{%raw%}

if sys.version_info[0] == 2:
    from xmlrpclib import Server
    
if sys.version_info[0] == 3:
    #from xmlrpclib import Server
    from xmlrpc.client import ServerProxy
    Server = ServerProxy

from supervisor.xmlrpc import SupervisorTransport

transport = SupervisorTransport(supervisor_rpc_user, supervisor_rpc_pass,
    supervisor_rpc_address)
server = Server(supervisor_rpc_address, transport)

def get_all_process():
    """
    这个函数是产生 lld 数据的
    {
        "data":[
            {
                "{#PROCNAME}": "app1"
            },
            {
                "{#PROCNAME}": "app2"
            }
        ]
    }
    """
    
    all_process_info = server.supervisor.getAllProcessInfo()
    #response = server.system.listMethods()
    #response = server.system.listMethods()
    all_process = [ {"{#PROCNAME}": proc['group']+ ':' +proc['name']} for proc in all_process_info ]
    all_process_dict = {"data": all_process}
    return all_process_dict

def get_proc_stat(proc_name):
    """
    STOPPED 0
    STARTING 10
    RUNNING 20
    BACKOFF 30
    STOPPING 40
    EXITED 100
    FATAL 200
    UNKNOWN 1000
    """
    try:
        proc_info = server.supervisor.getProcessInfo(proc_name)
    except Exception as e:
    # http://supervisord.org/subprocess.html#process-states
        return 1000
    else:
        return proc_info.get('state')
        

def get_supervisor_stat():
    """
    2	FATAL	Supervisor has experienced a serious error.
    1	RUNNING	Supervisor is working normally.
    0	RESTARTING	Supervisor is in the process of restarting.
    -1	SHUTDOWN	Supervisor is in the process of shutting down.
    """
    try:
        supervisor_stat = server.supervisor.getState()
    except Exception as e:
        # 自定义3 是连接失败
        return 3
    else:
        return supervisor_stat.get('statecode')


def main():
    if len(sys.argv) > 1:
        arg1 = sys.argv[1]
        if arg1 == 'self_check':
            print(get_supervisor_stat())
        else:
            print(get_proc_stat(sys.argv[1]))
    else:
        print(json.dumps(get_all_process()))


if __name__ == '__main__':
    main()
{%endraw%}

