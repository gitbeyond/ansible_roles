# -*- coding: utf-8 -*-
# editor: wanghaifeng@idstaff.com
# create date: 2021/02/02
# 脚本的作用是根据自己的网段，去 redis 中找到相应的 ip 池，获取一个可用的ip
# 把获得的 ip, gateway， nameservers 信息设置到虚拟机中
# 脚本需要在 python-2.7 下运行，有些语法，比如 filter 函数直接返回列表，这在3.x中返回的可能是迭代器



# 参考
# https://libvirt.org/hooks.html : Hooks for specific system management


# yum install python-netifaces
import netifaces
import sys
# pip install redis
import redis
import json
import os
import subprocess
import logging
from IPy import IP
import pysnooper
import libvirt
from xml.dom.minidom import parseString
import guestfs
import time


redis_server = '10.6.36.11'
redis_port = 6379
redis_db = 0
redis_password = None
# redis 中网络键名后缀
network_free_ip_pool_key_suffix = '_free_pool'
network_gateway_key_suffix = '_gateway'
network_nameservers_key_suffix = '_nameservers'
network_exclude_ip_key_suffix = '_exclude_ip'
network_allocate_ip_pool_key_suffix = '_allocation'
network_allocate_tmp_ip_pool_key_suffix = '_tmp_allocation'

# 生成的ip配置文件临时放在这个目录下,会以vm名字再建一层目录
vm_ip_work_dir = '/tmp'

#host_manager_net = '10.6.36.0'
host_manager_net = None

logging.basicConfig(level=logging.DEBUG,
                    format='%(asctime)s - %(filename)s[line:%(lineno)d] - %(funcName)s - %(levelname)s: %(message)s')

vm_name = sys.argv[1]
vm_boot_step = sys.argv[2]
vm_boot_step_stat =sys.argv[3]

#from libvirt_to_nano.libvirt_hook_set_ip import check_vm_is_set_ip

redis_cli = redis.StrictRedis(host=redis_server, port=redis_port, 
            db=redis_db, password=redis_password)

# virt_conn = libvirt.open("qemu:///system")
# vm_obj = virt_conn.lookupByName(vm_name)


#vm_xml_string = vm_obj.XMLDesc()
vm_xml_string = sys.stdin.read()
vm_xml = parseString(vm_xml_string)
vm_uuid = vm_xml.getElementsByTagName("uuid")[0].firstChild.data
def get_host_ip(network=None):
    # 获取这个ip的目的是为了把虚拟机uuid写入redis中时，带上这个ip,好方便知道虚拟机所在的host
    # 获取本机的ip,如果本机有多个ip,那么需要指定一个参数，类似于 192.16.5.0 这样
    # 用于获取这个网段内的ip
    # 如果没有指定，那么返回默认网关设备上的ip
    all_link = netifaces.interfaces()
    all_ip = [ {"link": link, "addr": netifaces.ifaddresses(link).get(netifaces.AF_INET)[0]['addr']} for link in all_link 
                if netifaces.ifaddresses(link).get(netifaces.AF_INET) ]
    ip_link = {}
    if network:
        network_str = '.'.join(network.split('.')[:3])
        ip_link = filter(lambda x: network_str in x.get('addr'), all_ip )[0]
        #return link_ip
    else:
        """
        In [243]: netifaces.gateways()
        Out[243]: {2: [('10.6.36.1', 'br0', True)], 'default': {2: ('10.6.36.1', 'br0')}}

        In [246]: netifaces.gateways()['default'][2]
        Out[246]: ('10.6.36.1', 'br0')

        """
        default_link = netifaces.gateways()['default'][2][1]
        ip_link = filter(lambda x: default_link == x.get('link'), all_ip )[0]
    
    return ip_link

def check_vm_is_set_ip(vm_uuid, redis_cli):
    host_ip = get_host_ip()['addr']
    vm_uuid_key = host_ip + ':' + vm_uuid
    vm_tmp_ip = redis_cli.smembers(vm_uuid_key)
    if vm_tmp_ip:
        return True
    else:
        return False

if vm_name.startswith("guestfs"):
    logging.debug("the vm_name is: %s, now exit." % vm_name)
    sys.exit(0)
        
if check_vm_is_set_ip(vm_uuid, redis_cli):
    sys.exit(0)
else:
    sys.exit(1)