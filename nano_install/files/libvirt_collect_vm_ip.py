# -*- coding: utf-8 -*-
# editor: wanghaifeng@idstaff.com
# create date: 2021/02/12

"""
脚本的逻辑：
1. 获取vm内的ip信息
2. 获取vm的mac地址，通过 xml 中的 interface 信息
3. 找到 ip信息中的 mac 地址与 interface 的mac 地址一致的网桥，比如 br0
4. 通过br0找到vm ip信息所在的网段，比如 172.16.5.0/24
5. 在 redis 中找到这个网段的信息，将其进行记录

至所以使用mac地址对比的方法，是为了保持准确性，比如在测试环境中，
    其上有虚拟网卡 cloudbr0 这种情况，所以目前来看，如果找不到其 hwaddr，就无法记录其ip信息。

使用前提：
1. 已定义了本宿主机所在的网段的ip池
2. 虚拟机使用的是bridge网络，桥接到了宿主机的通信网卡上，也就是说虚拟机与宿主机在同一个网络内
3. 如果没有安装qga, 那么虚拟机的配置文件一定要有 HWADDR, IPADDR, NETMASK 属性
"""


# 获取所有的vm对象

import libvirt
import guestfs
import redis
from xml.dom.minidom import parseString
#from IPy import IP
from ipaddress import IPv4Interface
import logging

from libvirt_set_static_ip import guestfs_mount_root, ip_conf_file, vm_xml, get_host_ip, static_ip_pool
from libvirt_set_static_ip import get_net_from_link


logging.basicConfig(level=logging.DEBUG,
                    format='%(asctime)s - %(filename)s[line:%(lineno)d] - %(funcName)s - %(levelname)s: %(message)s')


libvirt_url = 'qemu:///system'

redis_server = '10.6.36.11'
redis_port = 6379
redis_db = 0
redis_password = None
# 这个可以直接获取所有的vm对象，是一个列表，每一项直接是 vm 对象,包含启动的和非启动的
# virt_conn.listAllDomains()


# 类的作用是传入一个 libvirt 的 vm 对象
# 可以返回vm的ip
# 如果虚拟机是运行的
#   首先通过 interfaceAddresses(source=1) 方法
#   没有获取到的话，就通过guestfs 库去获取 vm 的 ip 配置文件(如果虚拟机是用 dhcp 获取ip,那么就无能为力了)
# 如果虚拟机没有运行，那么直接通过 guestfs 库去获取
# 
# 如果都没有获取到，那么可能是:
# 1. 此vm没有配置ip
# 2. 此vm正在安装os,或者没有os
class vm_ip(object):
    # 这个脚本不是在 hook 中调用，所以可以使用 libvirt 的 api
    """
    In [60]: vm_ip_obj.get_ip()
    Out[60]: [{'addr': '10.6.36.189', 'netmask': "255.255.255.0", 
        'prefix': '24', 'hwaddr': '00:16:3e:e2:c9:0f'}]
    """
    def __init__(self, vm_obj):
        self.vm_obj = vm_obj
        self.vm_name = self.vm_obj.name()
        self.vm_uuid = self.vm_obj.UUIDString()
        # 虚拟机的 mac 地址列表
        self.vm_macs = []
        self.ip_info = []
        # 这里也可以使用 qga 来获取相关的信息,但是qga必须虚拟机是启动状态的，同时无法分辩哪个是真正的物理网卡
        # 所以必须获得虚拟机真正的mac地址
        # 使用 vm_xml 类初始化一个 xm_xml 对象
        self.vm_xml_obj = vm_xml(self.vm_obj.XMLDesc())
        # 获取虚拟机的 mac 地址信息
        self.vm_macs = self.vm_xml_obj.get_macs()
        self.vm_mac_addrs = [ vm_mac.get('mac_address').encode() for vm_mac in self.vm_macs ]
    def get_ip_from_qga(self):
        """
        In [26]: v2.interfaceAddresses(source=1)
        Out[26]: 
        {'eth0': {'addrs': [{'addr': '10.6.36.50', 'prefix': 24, 'type': 0},
        {'addr': 'fe80::216:3eff:fee2:c90f', 'prefix': 64, 'type': 1}],
        'hwaddr': '00:16:3e:e2:c9:0f'},
        'lo': {'addrs': [{'addr': '127.0.0.1', 'prefix': 8, 'type': 0},
        {'addr': '::1', 'prefix': 128, 'type': 1}],
        'hwaddr': '00:00:00:00:00:00'}}
        """
        #vm_xml_obj = vm_xml(self.vm_obj.XMLDesc())
        #self.vm_macs = vm_xml_obj.get_macs()
        #vm_mac_addrs = [ vm_mac.get('mac_address') for vm_mac in self.vm_macs ]
        my_ip_info = []
        # 如果vm是运行的
        if self.vm_obj.isActive():
            try:
                # 通过 interfaceAddresses() 来获取ip信息
                ip_info = self.vm_obj.interfaceAddresses(source=1)
            except Exception as e:
                raise
            else:
                for key in ip_info:
                    if ip_info[key]['hwaddr'] in self.vm_mac_addrs:
                        for addr in ip_info[key]['addrs']:
                            # type == 0 是ipv4的地址
                            if addr['type'] == 0:
                                ip_with_prefix = addr['addr'] + '/' + str(addr['prefix'])
                                my_netmask = str(IPv4Interface(ip_with_prefix.decode()).netmask)
                                my_ip_info.append({'addr': addr['addr'], 'prefix': addr['prefix'], 
                                    'netmask': str(my_netmask), 'hwaddr': ip_info[key]['hwaddr']})
                self.ip_info = my_ip_info
                return self.ip_info

    # 这里还有个问题，就是返回的netmask是 255.255.255.0 的形式
    # 获取一个 dhcp 配置的示例
    # In [7]: vm_ip_obj.get_ip_from_guestfs()
    # Out[7]: [{'addr': None, 'netmask': None}]
    def get_ip_from_guestfs(self):
        my_ip_info = []
        g = guestfs.GuestFS(python_return_dict=True)
        g.add_domain(self.vm_name, readonly=True)
        g.launch()
        root_dev = guestfs_mount_root(g)
        if isinstance(root_dev, str):
            if_files = g.ls('/etc/sysconfig/network-scripts/')
            # 找到以 ifcfg 开头且不是以 lo 结尾的网卡配置文件
            if_confs = filter(lambda x: x.startswith("ifcfg") and not x.endswith("lo"), if_files)
            for if_conf in if_confs:
                if_conf_content = g.cat("/etc/sysconfig/network-scripts/%s" % if_conf)
                # 获取一个ip_conf_file 的对象
                if_conf_obj = ip_conf_file(if_conf_content)
                # 获取mac地址
                if_conf_hwaddr = if_conf_obj.get('HWADDR')
                if if_conf_hwaddr:
                    if_conf_hwaddr = if_conf_hwaddr.lower()
                # 获取ipaddr
                if_conf_ipaddr = if_conf_obj.get('IPADDR')
                # 获取子网掩码
                if_conf_netmask = if_conf_obj.get('NETMASK')
                # 子网掩码的数字表示形式的变量
                my_prefix = ''
                if if_conf_ipaddr and if_conf_netmask:
                    ip_with_netmask = if_conf_ipaddr + '/' + if_conf_netmask
                    my_prefix = IPv4Interface(ip_with_netmask.decode()).with_prefixlen.split('/')[1]
                if if_conf_hwaddr in self.vm_mac_addrs:
                    my_ip_info.append({'addr': if_conf_ipaddr, 'netmask': if_conf_netmask, 
                        'prefix': my_prefix, 'hwaddr': if_conf_hwaddr})

            self.ip_info = my_ip_info
            return self.ip_info
        else:
            raise ValueError("Can't find the root_dev, code:%s" % root_dev)
            #return root_dev

    def get_ip(self):
        # 这里之所以要进行 try是因为vm可能没有安装 qga
        try:
            my_ip_info = self.get_ip_from_qga()
        except Exception as e:
            try:
                return self.get_ip_from_guestfs()
            except Exception as e1:
                raise
        else:
            return my_ip_info
        
            

def main():
    virt_conn = libvirt.open(libvirt_url)
    redis_cli = redis.StrictRedis(host=redis_server, port=redis_port, 
            db=redis_db, password=redis_password)
    # 获取所有的vm对象
    all_doms = virt_conn.listAllDomains()
    # 是指获取宿主机的ip地址和网卡（网桥）名
    host_ip = get_host_ip()['addr']
    # 遍历所有的vm对象
    for dom in all_doms:
        logging.debug("begin vm:%s" % dom.name())
        try:
            # 获取vm_ip 的对象
            dom_ip_obj = vm_ip(dom)
            # 通过 vm_ip 对象获取ip 信息，是一个列表，列表中是字典
            dom_ips = dom_ip_obj.get_ip()
            logging.debug("dom_ips:%s" % dom_ips)
        except Exception as e:
            logging.error("get ip from vm:%s is failed." % dom.name())
        else:
            if not dom_ips:
                logging.debug("The dom_ips:% is invalid, now continue." % dom_ips)
                continue

            for dom_ip in dom_ips:
                # [{"type": "bridge","source_bridge": "br0","mac_address": "00:16:3e:e2:c9:0f"}]
                # dom_ips.vm_macs
                logging.debug("dom_ip_obj.vm_macs: %s" % dom_ip_obj.vm_macs)
                logging.debug("dom_ip: %s" % dom_ip)
                # 获取虚拟机ip 的网桥
                dom_ip_bridge = filter(lambda x: x['mac_address'] == dom_ip['hwaddr'], dom_ip_obj.vm_macs)[0]['source_bridge']
                # 获取虚拟机网桥的 network 
                dom_ip_bridge_net = get_net_from_link(dom_ip_bridge)[0]
                static_ip_obj = static_ip_pool(redis_cli, host_ip, dom_ip_bridge_net, dom.name(), dom.UUIDString())
                static_ip_obj.direct_allocate(dom_ip['addr'])



if __name__ == '__main__':
    main()
