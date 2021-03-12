# -*- coding: utf-8 -*-
# editor: wanghaifeng@idstaff.com
# create date: 2021/02/02
# 脚本的作用是根据自己的网段，去 redis 中找到相应的 ip 池，获取一个可用的ip
# 把获得的 ip, gateway， nameservers 信息设置到虚拟机中
# 脚本需要在 python-2.7 下运行，有些语法，比如 filter 函数直接返回列表，这在3.x中返回的可能是迭代器

"""
v2版本主要是更新了 ip_conf_file 的部分

1. 脚本对于使用dhcp的虚拟机无能为力，（这里需要再加一个判断，如果其使用dhcp就跳过，但是这个也不好判断啊）
    * 所以不能使用 dhcp 与静态ip相结合的环境
    * 像这里的测试环境 admin.cloudstack-node-1 就是使用 dhcp 获取ip的，此时，如果这台机器开机，那就要出问题
        * 按照目前的逻辑，会为这台机器分配一个ip,但是其内的cloud-init又会覆盖此ip,重新使用dhcp获取
        * 所以上次分的ip在数据库，的确是这台机器的，但是这台机器却并未使用
2. 另外再配合上 “将已有虚拟机ip记录至redis”的脚本，这样可以实现，
    * ip池只要记录排除宿主机ip,其他静态设置ip的虚拟机都可以管理起来
"""

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
import uuid

from libvirt_set_static_ip import ip_conf_file, get_host_ip, get_net_from_link
from libvirt_set_static_ip import guestfs_mount_root, vm_xml

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






# 获取一个空闲ip，及网关,dns信息
# 获取后的ip在临时的分配集合中
@pysnooper.snoop()
def get_free_ip_from_redis(redis_cli, network_str, vm_uuid):
    # redis_cli
    # network_str: like 10.6.36.0/24 
    # vm_uuid, 用来记录与临时ip的对应关系
    network_free_ip_pool_key = network_str + network_free_ip_pool_key_suffix
    network_gateway_key = network_str + network_gateway_key_suffix
    network_nameservers_key = network_str + network_nameservers_key_suffix
    # network_allocate_ip_pool_key = network_str + network_allocate_ip_pool_key_suffix

    # 刚拿了一个空闲ip后，先写入这里，设置失败后，将其再放回 ip 池
    network_allocate_tmp_ip_pool_key = network_str + network_allocate_tmp_ip_pool_key_suffix
    
    # 先判断临时的池中是否有此 vm 没有设置好的ip
    network_allocate_tmp_ip_pool_value = list(redis_cli.smembers(network_allocate_tmp_ip_pool_key))
    #network_allocate_tmp_ip_pool_dict = [ {"vm_uuid": ip.split(":")[0], "ip": ip.split(":")[1]} for ip in 
    #    network_allocate_tmp_ip_pool_value ]
    # 这里为真的话，就说明 vm 之前申请过ip,但是整个流程没有走完，失败了
    vm_ip = ""
    logging.debug("network_allocate_tmp_ip_pool_value: %s" % network_allocate_tmp_ip_pool_value)
    for uuid_ip in network_allocate_tmp_ip_pool_value:
        if vm_uuid == uuid_ip.split(":")[0]:
            # 那就还把这个 ip 返回
            vm_ip = uuid_ip.split(":")[1]
            break
    
    pipe = redis_cli.pipeline()
    # 如果ip已经存在
    if vm_ip:      
        pipe.get(network_gateway_key)
        # 返回的是一个 set 
        pipe.smembers(network_nameservers_key)
        # 获取临时池中的ip
        pipe_ret = pipe.execute()
        # 把集合改成list
        pipe_ret[1] = list(pipe_ret[1])
        pipe_ret.append(vm_ip)
    else:
        # 获得锁
        identifier = acquire_lock('get_ip')
        pipe.get(network_gateway_key)
        # 返回的是一个 set 
        pipe.smembers(network_nameservers_key)
        # 获取一个空闲ip
        pipe.spop(network_free_ip_pool_key)
        # 获取临时池中的ip
        pipe_ret = pipe.execute()
        # 释放锁
        release_lock('get_ip', identifier)
        redis_cli.sadd(network_allocate_tmp_ip_pool_key, vm_uuid + ":" + pipe_ret[2])
        # 把集合改成list
        pipe_ret[1] = list(pipe_ret[1])
    logging.debug("pipe_ret: %s" % pipe_ret)
    return pipe_ret
    # 如果拿了一个 ip ，先将其写入临时的区域中，
    # 防止并未为 vm 设置成功，那么还要再写回ip池
    # 设置成功后，才对其进行记录，记录是 hostip_vm_uuid: [ip1, ip2]

def move_ip_from_free_to_allocate(redis_cli, network_str, vm_ip, vm_uuid):
    # 把ip直接从ip池中移动到已分配池中
    network_free_ip_pool_key = network_str + network_free_ip_pool_key_suffix
    network_allocate_ip_pool_key = network_str + network_allocate_ip_pool_key_suffix
    host_ip = get_host_ip()['addr']
    pipe = redis_cli.pipeline()

    vm_uuid_key = host_ip + ':' + vm_uuid
    identifier = acquire_lock('get_ip')
    pipe.smove(network_free_ip_pool_key, network_allocate_ip_pool_key, vm_ip)
     # 将 ip 当作 key, 宿主机ip:vm_uuid:vm_name 当做 value
    pipe.set(vm_ip, vm_uuid_key)
    # 把 宿主机ip:vm_uuid:vm_name 当作key, 把ip加入到集合当中
    pipe.sadd(vm_uuid_key, vm_ip) 
    # 获取临时池中的ip
    pipe_ret = pipe.execute()
    # 释放锁
    release_lock('get_ip', identifier)
    return pipe_ret


# 在把ip配置文件复制到虚拟机内之后
# 把 ip 写入到已分配池内
def write_ip_to_allocate_pool(redis_cli, vm_uuid, ip_info):
    # 先尝试获取，看看是否已经有这个key, 有的话，要报错
    # ip_info 就是通过 vm_set_ip() 函数得到的列表中的某一项
    ip = ip_info['ip_info'][2]
    
    vm_tmp_uuid = redis_cli.get(ip)
    if vm_tmp_uuid:
        logging.error("The ip:%s of vm:%s already exist." % (ip,vm_uuid))
        return False
    else:
        host_ip = get_host_ip()['addr']
        network_str = ip_info['network_str']
        network_allocate_ip_pool_key = network_str + network_allocate_ip_pool_key_suffix
        # 刚拿了一个空闲ip后，先写入这里，设置失败后，将其再放回 ip 池
        network_allocate_tmp_ip_pool_key = network_str + network_allocate_tmp_ip_pool_key_suffix
        # 临时存储池中的ip信息，要将其挪往正式分配池的set中

        tmp_ip_value = vm_uuid + ':' + ip
        # 这里再加个 vm_name 方便查看吧, 还是不能加 vm_name,加上后vm_name一改名，这里也得跟着操作，否则信息就乱了
        #vm_uuid_key = host_ip + ':' + vm_uuid + ':' + vm_name
        vm_uuid_key = host_ip + ':' + vm_uuid
        pipe = redis_cli.pipeline()
        # 将 ip 当作 key, 宿主机ip:vm_uuid:vm_name 当做 value
        pipe.set(ip, vm_uuid_key)
        # 把 宿主机ip:vm_uuid:vm_name 当作key, 把ip加入到集合当中
        pipe.sadd(vm_uuid_key, ip) 
        # 从临时的池的集合中删除
        pipe.srem(network_allocate_tmp_ip_pool_key, tmp_ip_value)
        # 将ip信息添加到已分配池中
        pipe.sadd(network_allocate_ip_pool_key,tmp_ip_value.split(':')[1])
        return pipe.execute()
        
# 分配ip失败的时候，把ip写回分配池中
def write_back_to_ip_pool(ip_info, vm_uuid, redis_cli):
    # ip_info 是一个列表
    my_ip_info = filter(lambda x: x['vm_uuid'] == vm_uuid, ip_info)[0]
    ip = my_ip_info['ip_info'][2]
    network_str = my_ip_info['network_str']
    
    network_free_ip_pool_key = network_str + network_free_ip_pool_key_suffix
    # 刚拿了一个空闲ip后，先写入这里，设置失败后，将其再放回 ip 池
    network_allocate_tmp_ip_pool_key = network_str + network_allocate_tmp_ip_pool_key_suffix
    tmp_ip_value = vm_uuid + ':' + ip
    pipe = redis_cli.pipeline()
    pipe.srem(network_allocate_tmp_ip_pool_key, tmp_ip_value)
    pipe.sadd(network_free_ip_pool_key, tmp_ip_value.split(':')[1])
    return pipe.execute()

def check_vm_is_set_ip(vm_uuid, redis_cli):
    host_ip = get_host_ip()['addr']
    vm_uuid_key = host_ip + ':' + vm_uuid
    vm_tmp_ip = redis_cli.smembers(vm_uuid_key)
    if vm_tmp_ip:
        return True
    else:
        return False


#获取一个锁
# lock_name：锁定名称
# acquire_time: 客户端等待获取锁的时间
# time_out: 锁的超时时间
def acquire_lock(lock_name, acquire_time=10, time_out=10):
    """获取一个分布式锁"""
    identifier = str(uuid.uuid4())
    end = time.time() + acquire_time
    lock = "string:lock:" + lock_name
    while time.time() < end:
        if redis_cli.setnx(lock, identifier):
            # 给锁设置超时时间, 防止进程崩溃导致其他进程无法获取锁
            redis_cli.expire(lock, time_out)
            return identifier
        elif not redis_cli.ttl(lock):
            redis_cli.expire(lock, time_out)
        time.sleep(0.001)
    return False

#释放一个锁
def release_lock(lock_name, identifier):
    """通用的锁释放函数"""
    lock = "string:lock:" + lock_name
    pipe = redis_cli.pipeline(True)
    while True:
        try:
            pipe.watch(lock)
            lock_value = redis_cli.get(lock)
            if not lock_value:
                return True

            if lock_value.decode() == identifier:
                pipe.multi()
                pipe.delete(lock)
                pipe.execute()
                return True
            pipe.unwatch()
            break
        except redis.excetions.WacthcError:
            pass
    return False



# 生成虚拟机ip配置文件的
def gen_ip_conf(ip, netmask, mac, gateway, nameservers, dev_name, vm_name, is_gateway):
    # dev_name 是类似 eth0 , ens32 这样的名字
    # vm_name 是虚拟机的名称
    # 根据ip信息生成ip配置文件

    # 先判断是否需要配置默认网关
    ip_conf="""DEVICE=%s
NAME=%s
BOOTPROTO="static"
IPADDR=%s
NETMASK=%s
HWADDR=%s
NM_CONTROLLED=no
TYPE=Ethernet
ONBOOT=yes
IPV6INIT="no"
DNS1=%s
DNS2=%s
USERCTL=no""" % (dev_name, dev_name, ip, netmask, mac, nameservers[0], nameservers[1])
    # GATEWAY=%s
    if is_gateway:
        ip_conf = ip_conf + '\nGATEWAY=%s' % gateway

    tmp_dir = vm_ip_work_dir + '/' + vm_name
    subprocess.call("mkdir -p %s" % tmp_dir, shell=True)
    dev_conf_file = tmp_dir + '/ifcfg-' + dev_name
    with open(dev_conf_file, 'w') as dev_file:
        dev_file.write(ip_conf)
    
    return dev_conf_file


# yum install python-netifaces
@pysnooper.snoop()
def vm_set_ip(redis_cli, vm_xml_string):
    # 生成虚拟机的网络信息
    # vm 是虚拟机的name
    """
    get_host_ip()
    # 返回如下数据
    {'link': 'br0', 'addr': '10.6.36.11'}
    """
    # 参数1是虚拟机的名字
    #vm_obj = virt_conn.lookupByName(vm_name)
    # 虚拟机的
    #vm_ip_key = get_host_ip(host_manager_net)['addr'] + '_' + vm_uuid
    # 获取vm的interface,有可能会有多个，当前只考虑桥接的情况
    # 根据其 <source bridge='br0'/> 中的 br0, 获取 br0 的网段，及 netmask 信息，
    # 然后根据这个信息从 redis 中去相应的 ip 池中取 ip,以及 gateway, dnsserver 等等

    # 同时还需要获取 mac 地址，用来生成ip的配置文件
    #vm_xml = parseString(vm_xml_string)
    #vm_uuid = vm_xml.getElementsByTagName("uuid")[0].firstChild.data
    #vm_interfaces = vm_xml.getElementsByTagName("interface")
    #logging.debug("the vm_interfaces is:%s" % vm_interfaces)
    # vm_macs 存储的信息如 [{'source': u'br0', 'mac': u'00:16:3e:e2:c9:0f', 
    #                       'network_str': ['10.6.36.0/24', '255.255.255.0']}]
    vm_xml_obj = vm_xml(vm_xml_string)
    vm_uuid = vm_xml_obj.get_uuid()
    vm_name = vm_xml_obj.get_name()

    vm_macs = []
    for interface in vm_xml_obj.get_macs():
        # 获取mac 地址
        mac_address = interface.get('mac_address')
        # 获取 bridge 名称
        source_bridge = interface.get('source_bridge')
        # 根据 bridge 名称获取 bridge 所在的网段名和netmask
        dev_net = get_net_from_link(source_bridge)
        
        vm_macs.append({"mac": mac_address, "source": source_bridge, 
                            "network_str": dev_net[0], "netmask": dev_net[1], 
                            "is_default_gateway": dev_net[2],
                            "vm_name": vm_name, "vm_uuid": vm_uuid})
    # 这里有一个问题是：不知道网卡在虚拟机内的名称是什么？
    logging.debug("the vm_macs is:%s" % vm_macs)
    # 根据网络信息从 redis 中获取可用ip
    for vm_mac in vm_macs:
        network_str = vm_mac['network_str']
        netmask = vm_mac['netmask']
        # 网关， dns， ip
        # get_free_ip_from_redis() 返回值 ["10.6.36.1", ["202.106.0.20", "8.8.8.8"], "10.6.36.125"]
        ip_info = get_free_ip_from_redis(redis_cli, network_str, vm_uuid)
        vm_mac['ip_info'] = ip_info
        # 生成ip配置文件
        vm_mac['ip_conf_file'] = gen_ip_conf(ip_info[2], netmask, vm_mac['mac'], 
            ip_info[0], ip_info[1], 'eth' + str(vm_macs.index(vm_mac)), vm_name, 
            vm_mac['is_default_gateway'])
    
    return vm_macs
    # [{'ip_info': ['10.6.36.1', ['202.106.0.20', '8.8.4.4'], '10.6.36.58'], 
    #   'ip_conf_file': '/tmp/admin.test1/ifcfg-eth0', 
    #   'netmask': '255.255.255.0', 
    #   'network_str': '10.6.36.0/24', 
    #   'source': u'br0', 
    #   'mac': u'00:16:3e:e2:c9:0f'}]
    #print(vm_macs)



# 根据ip_info 把ip的配置文件写入虚拟机内
@pysnooper.snoop()
def copy_ip_file_to_vm(ip_info, vm_name, redis_cli):
    # ip_info 就是指 ip 的综合信息，类似下面，是一个列表，由vm_set_ip() 函数生成
    #  [{'ip_info': ['10.6.36.1', ['202.106.0.20', '8.8.4.4'], '10.6.36.58'], 
    #   'ip_conf_file': '/tmp/admin.test1/ifcfg-eth0', 
    #   'netmask': '255.255.255.0', 
    #   'network_str': '10.6.36.0/24', 
    #   'source': u'br0', 
    #   'mac': u'00:16:3e:e2:c9:0f'}]
    # vm_name 是虚拟机的名字
    """
    # 这里还是要有标准化，比如说是否使用lvm, 要不然这里是不知道挂载哪个分区的
    In [70]: g.list_devices()
    Out[70]: ['/dev/sda', '/dev/sdb', '/dev/sdc']

    # 这个分区只有 sdb 的信息
    In [71]: g.list_partitions()
    Out[71]: ['/dev/sdb1', '/dev/sdb2']

    In [78]: g.list_filesystems()
    Out[78]: 
    {'/dev/centos/root': 'xfs',
    '/dev/centos/swap': 'swap',
    '/dev/nano/data': 'ext4',
    '/dev/sda': 'iso9660',
    '/dev/sdb1': 'xfs'}

    In [118]: g.ls("/etc/sysconfig/network-scripts")

    In [82]: g.upload("/tmp/admin.test1/ifcfg-eth0", "/tmp/ifcfg-eth0")
    In [84]: g.close()

    # 筛选出正常的网卡
    In [123]: filter(lambda x: x.startswith("ifcfg") and not x.endswith("lo"), if_files)
    Out[123]: ['ifcfg-eth0', 'ifcfg-lo']

    In [125]: g.cat('/etc/sysconfig/network-scripts/ifcfg-eth0').split("\n")
    Out[125]: 
    ['# Created by cloud-init on instance boot automatically, do not edit.',
    '#',
    'BOOTPROTO=dhcp',
    'DEVICE=eth0',
    'HWADDR=00:16:3e:e2:c9:0f',
    'ONBOOT=yes',
    'TYPE=Ethernet',
    'USERCTL=no',
    '']
    """
    
    #vm_obj = virt_conn.lookupByName(vm_name)
    vm_uuid = filter(lambda x: x['vm_name'] == vm_name, ip_info)[0]['vm_uuid']
    # 这里还得先检查一下，vm是否已经配置了ip,这个去 redis 中检查即可，通过 vm_uuid 来获取ip
    # 直接这么判断不合理，因为有些虚拟机，其ip很可能是之前就已经设置好的了
    # 也就说没有使用此脚本进行设计，这些虚拟机的ip，应该通过libvirt尝试获取，并将其写入redis中
    
    # 这个操作已经在另一个检查的脚本里做了，不过放在这里也没有问题
    if check_vm_is_set_ip(vm_uuid, redis_cli):
        logging.info("the vm:%s already set ip:%s" % (vm_name, ip_info))
        #time.sleep(10)
        subprocess.call("virsh start %s" % vm_name, shell=True)
        return True

    g = guestfs.GuestFS(python_return_dict=True)
    g.add_domain(vm_name)
    
    # 启动 guestfs vm,这里sleep(1)的时候，launch()方法是不成功的
    time.sleep(60)
    try:
        g.launch()
    except Exception as e:
        logging.error("g.launch() failed. %s" % e)
        sys.exit(10)
    
    # 进行实际的挂载操作
    root_dev = guestfs_mount_root(g)
    if_files = []
    if isinstance(root_dev, str):
        if_files = g.ls("/etc/sysconfig/network-scripts/")
    else:
        # 如果没能挂载成功，那可能是虚拟机还没有安装操作系统，应该正常开机才行
        logging.debug("g.mount() is failed, it return %s. now start vm" % root_dev)
        subprocess.call("virsh start %s" % vm_name, shell=True)
    # 如果 if_files 有值的话，这个其实就是 /etc/sysconfig/network-scripts 下面的所有文件列表
    # 然后把 if_confs 中存储的是正常使用的网卡配置文件列表
    if_confs = []
    if if_files:
        # 找到以 ifcfg 开头且不是以 lo 结尾的网卡配置文件
        if_confs = filter(lambda x: x.startswith("ifcfg") and not x.endswith("lo"), if_files)

    ip_write_ret = []
    # 如果网卡配置文件有值
    if if_confs:
        # 遍历这个网卡配置文件列表
        for if_conf in if_confs:
            if_conf_content = g.cat("/etc/sysconfig/network-scripts/%s" % if_conf)
            if_conf_obj = ip_conf_file(if_conf_content)
            
            #if_conf_content_list = if_conf_content.split("\n")

            # 这里先判断其配置文件中是否已经有ip了
            # 可能会有一些虚拟机没有使用脚本来进行管理ip
            # 这里也可以加，也可以不加，加上的话更合适一些，合适之处在于检查的更全面，
            # 不合适之处在于，总不能等着这些虚拟机重启或者为了这个而去把虚拟机重启
            # 应该有一个单独的脚本把已存在虚拟机的ip给全部收集好，写入已分配池

            # 如果已经有IP地址了，那么检查 netmask 与本网络是否匹配
            # 如果匹配，那么之前生成的ip地址信息就需要作废，写回ip池
            # 同时把已存在的这个ip从ip池中移出，挪到到已分配池中


            # 获取网卡配置文件中的 mac 地址
            #if_conf_hwaddr = filter(lambda x: x.startswith("HWADDR"), if_conf_content_list )[0].split("=")[1]
            if_conf_hwaddr = if_conf_obj.get('HWADDR')
            if_conf_ipaddr = if_conf_obj.get('IPADDR')
            # 获取本网卡的 ip_info 数据结构
            vm_ip_info = filter(lambda x: x['mac'] == if_conf_hwaddr, ip_info)[0]

            # 如果vm已经有ip了(但是这个ip没有在redis中记录)
            if if_conf_ipaddr:
                # 先把获取到的空闲ip写回ip池
                write_back_to_ip_pool(ip_info, vm_uuid, redis_cli)
                # 直接把此ip从ip池挪到已分配池
                # 这里很可能此ip已经被分出去了，那么在此之前就会发生ip重用的问题了
                # 或者在测试时，ip分给了某台机器，然后又删了这个ip的记录
                # 总之如果ip池中没有这个ip,那么就会报错
                move_ip_ret = move_ip_from_free_to_allocate(redis_cli, vm_ip_info['network_str'], 
                    if_conf_ipaddr, vm_uuid)
                logging.debug("move_ip_from_free_to_allocate is: %s" % move_ip_ret)
                # 这里也可以写成 continue ,继续下一次循环
                return move_ip_ret           

            # 获取网卡配置文件中的 DEVICE 名称, 这里有可能得到空列表
            if_conf_device = if_conf_obj.get('DEVICE')
            if_conf_name = if_conf_obj.get('NAME')
            # 获取配置文件的位置
            vm_ip_info_file = vm_ip_info['ip_conf_file']
            
            # 判断if_conf_device 是否有值
            if if_conf_device:
                pass
            else:
                # 如果没值
                if if_conf_name:
                    if_conf_device = if_conf_name
                else:
                    logging.debug("DEVICE and NAME in %s aren't exist." % if_conf_content)
                    return False

            # 判断虚拟机中网卡的名字是否与当前文件匹配
            if vm_ip_info_file.endswith(if_conf_device):
                # 如果与网卡名一致，那么直接复制到vm当中
                #pass
                g.upload(vm_ip_info_file, '/etc/sysconfig/network-scripts/ifcfg-%s' % if_conf_device)
                g.upload(vm_ip_info_file, '/etc/ifcfg-%s' % if_conf_device)
            else:
                # 修改网卡文件名与内容，写入新的文件, vm_ip_info_file 是待修改的文件
                with open(vm_ip_info_file, 'r') as vm_ip_info_file_fd:
                    vm_ip_info_file_content = vm_ip_info_file_fd.read()
                
                # 自己生成的配置文件，0 是 DEVICE, 1是NAME
                vm_ip_info_file_obj = ip_conf_file(vm_ip_info_file_content)
                vm_ip_info_file_obj.set("DEVICE", if_conf_device)
                vm_ip_info_file_obj.set("NAME", if_conf_device)
                
                # 根据网卡名字生成的新的网卡配置文件本地文件名
                vm_new_ip_file = vm_ip_work_dir + '/' + vm_name + '/ifcfg-' + if_conf_device

                with open(vm_new_ip_file, 'w') as vm_new_ip_file_fd:
                    # 把修改后的内容写入到新的名字的网卡文件中
                    vm_new_ip_file_fd.write(vm_ip_info_file_obj.get_all_by_str())

                g.upload(vm_new_ip_file, '/etc/sysconfig/network-scripts/ifcfg-%s' % if_conf_device)
                g.upload(vm_new_ip_file, '/etc/ifcfg-%s' % if_conf_device)

            # 把ip正式写入到分配区中
            ip_write_ret.append(write_ip_to_allocate_pool(redis_cli, vm_uuid, vm_ip_info))
    return ip_write_ret

#print(get_host_ip("10.6.36.0"))
#print(get_host_ip())
logging.debug("script begin.")
redis_cli = redis.StrictRedis(host=redis_server, port=redis_port, 
            db=redis_db, password=redis_password)
virt_conn = libvirt.open("qemu:///system")

vm_name = sys.argv[1]
vm_boot_step = sys.argv[2]
vm_boot_step_stat =sys.argv[3]

#vm_xml_string = sys.stdin.read()


if __name__ == '__main__':
    logging.debug("args is:%s" % sys.argv)
    """
    root      27997  27995  0 15:28 ?        00:00:00 /data/apps/opt/python-libvirt/bin/python \
        /data/apps/data/wanghaifeng/mycode/python/python-gitlab/libvirt_to_nano/libvirt_hook_set_ip.py guestfs-ku76gyzb4ft1i4h5 prepare begin

    """

    if vm_name.startswith("guestfs"):
        logging.debug("the vm_name is: %s, now exit." % vm_name)
        sys.exit(0)

    vm_obj = virt_conn.lookupByName(vm_name)
    vm_xml_string = vm_obj.XMLDesc()
    vm_xml_obj = parseString(vm_xml_string)
    vm_uuid = vm_xml_obj.getElementsByTagName("uuid")[0].firstChild.data

    logging.debug("begin get ip_info.")
    ip_info = vm_set_ip(redis_cli, vm_xml_string)
    logging.debug("ip_info is:%s" % ip_info)
    if vm_boot_step == 'prepare' and vm_boot_step_stat == 'begin':
        try:
            copy_ret = copy_ip_file_to_vm(ip_info, vm_name,  redis_cli)
        except Exception as e:
            logging.error("%s setup ip failed. now release ip." % vm_name)
            write_back_to_ip_pool(ip_info, vm_uuid, redis_cli)
            sys.exit(1)
        else:
            if all(copy_ret):
                logging.debug("virsh start %s" % vm_name)
                subprocess.call("virsh start %s" % vm_name, shell=True)
            else:
                logging.error("copy_ip_file_to_vm() failed.")
                write_back_to_ip_pool(ip_info, vm_uuid, redis_cli)
    

#print(get_net_from_link("br0"))