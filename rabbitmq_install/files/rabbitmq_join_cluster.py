# -*- coding: utf-8 -*-
# 在没网的情况下，很可能不能安装这些包，因此不采用这种方式
#import pika
#from socket import gethostname
import subprocess
import sys
import json

#cluster_init_node='rabbit@kvm6'
cluster_init_node=sys.argv[1]
#cluster_node_type='disc'
cluster_node_type=sys.argv[2]
cluster_join_timeout='10'
rabbit_cmd='/data/apps/opt/rabbitmq/sbin/rabbitmqctl'
rabbit_conn_timeout='10'

#rabbit_cluster_status_cmd= rabbit_cmd + ' --formatter json' + ' --timeout' + rabbit_conn_timeout + ' cluster_status'
rabbit_base_cmd_line= [rabbit_cmd, '--formatter', 'json', '--timeout', rabbit_conn_timeout]
rabbit_cluster_status_cmd= rabbit_base_cmd_line + ['cluster_status']
rabbit_app_status_cmd = rabbit_base_cmd_line + ['status']
rabbit_app_stop_cmd = rabbit_base_cmd_line + ['stop_app']
rabbit_app_start_cmd = rabbit_base_cmd_line + ['start_app']
rabbit_app_reset_cmd = rabbit_base_cmd_line + ['reset']
rabbit_cluster_join_cmd = rabbit_base_cmd_line + ['join_cluster', cluster_init_node, '--'+cluster_node_type]



def get_cluster_status():
    cluster_status = subprocess.Popen(rabbit_cluster_status_cmd, stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    #print(cluster_status.returncode)
    cluster_status.wait()
    if cluster_status.poll() == 0:
        return cluster_status.communicate()[0]
    else:
        print("exec " + ' '.join(rabbit_cluster_status_cmd) + ' has error.')
        sys.exit(cluster_status.returncode)

cluster_status_json = get_cluster_status()
cluster_status = json.loads(cluster_status_json)

# 检测当前节点是否在集群内
def check_host_in_cluster():
    # 仅仅是检测节点数是否大于 1
    if len(cluster_status['running_nodes']) > 1:
        return True
    else:
        return False
    # 
    #fqdn = gethostname()
    # short name
    #host_s_name = fqdn.split('.')[0]
   
    #for name in [fqdn, host_s_name]:
    #    node_name = 'rabbit@' + name
    #    if node_name in cluster_status['running_nodes']:
    #        return True
    #else:
    #    return False

def rabbitmq_join_cluter():
    # 先检测 app 状态
    app_status = subprocess.Popen(rabbit_app_status_cmd, stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    app_status.wait()
    # 如果 app 是运行着的，那就 stop_app
    if app_status.poll() == 0:
        app_stop_ret = subprocess.Popen(rabbit_app_stop_cmd, stdout=subprocess.PIPE,stderr=subprocess.PIPE)
        print("rabbitmqctl stop_app")
        app_stop_ret.wait()
    
    # 停止之后执行加入集群
    cluster_join_ret = subprocess.Popen(rabbit_cluster_join_cmd, stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    print("rabbitmqctl join_cluster")
    cluster_join_ret.wait()
    if cluster_join_ret.poll() == 0:
        cluster_join_ret_json = cluster_join_ret.communicate()[0]
    else:
        cluster_join_ret_json = cluster_join_ret.communicate()[1]
    
    print(cluster_join_ret_json)
    # 启动 app
    cluster_start = subprocess.Popen(rabbit_cluster_start_cmd, stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    cluster_start.wait()
    if cluster_start.poll() == 0:
        return cluster_join_ret_json
   
    


#print(cluster_status['running_nodes'])
#print(check_host_in_cluster())

if check_host_in_cluster():
    print(cluster_status_json)
    sys.exit(0)


# 开始执行加入集群
print(rabbitmq_join_cluter())
sys.exit(10)
