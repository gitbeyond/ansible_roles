# -*- coding: utf-8 -*-
# editor: wanghaifeng@idstaff.com
# create date: 2021/01/19
# update date: 2021/02/22
# 脚本的作用是获取当前vm的信息，将其写入 cell 的数据文件中
# 
"""
这里要实现的操作是:
1. 获取所有正在运行的vm
2. 停止 cell， 将vm信息写入至cell的数据文件
3. 遍历这些vm,获取vm的信息
    * 如果 vm 的名字以 admin. 开头
        * 如果 vm 的名字存在于 cell 的数据文件中
            * 那么检查是否一致，不一致则更新，然后写入数据文件
        * 否则(没有在cell的数据文件中)
            * 将vm的数据文件写入 cell 中
    * 否则
        * 停止 vm, 为 vm 重新改名
        * 把 vm 的 qemu 的配置文件cp一份到新的名字
        * 把原文件移动至 /data/apps/var/nano/bak 目录下
        * 把新的vm的qemu的配置文件中的名字也修改成最新的
        * 启动改名后的 vm 
4. 启动 cell
"""

# 这个基本完善了，接下来准备将其复制到各个节点上，导入vm

# yum install  python-libvirt
import libvirt
# yum install python-libguestfs libguestfs
#import guestfs
from xml.dom.minidom import parseString
from xml.etree import ElementTree
import time
import sys
import os
import subprocess
import shutil
#import pysnooper
import json
import logging
# yum install mysql-connector-python
import mysql.connector


logging.basicConfig(level=logging.DEBUG,
                    format='%(asctime)s - %(filename)s[line:%(lineno)d] - %(levelname)s: %(message)s')

nano_work_dir = '/data/apps/var/nano/bak'
nano_base_dir = '/data/apps/opt/nano-cell'
nano_cell_instance_data = nano_base_dir + '/data/instance.data'
nano_cell_network_data = nano_base_dir + '/data/network.data'
nano_cell_storage_data = nano_base_dir + '/data/storage.data'

conn = libvirt.open("qemu:///system")
# 虚拟机关机时的超时时间
shutdown_wait_second = 2

nano_user = "admin"
nano_group = "admin"
vm_root_disk_t1 = "vda"
vm_root_disk_t2 = "sda"
vm_root_disks = [vm_root_disk_t1, vm_root_disk_t2]

mysql_config = {
    "host": "{{cmdb_mysql_host}}",
    "port": {{cmdb_mysql_port | int}},
    "user": "{{cmdb_mysql_user}}",
    "passwd": "{{cmdb_mysql_pass}}",
    "database": '{{cmdb_mysql_db}}',
    # by_oprelease
}
{%raw%}
# 通过vm的uuid从数据库中获取vm的ip信息
def get_vm_ip_by_uuid(vm_uuid):
    # F30AF495-61A6-49F5-A5DE-D279D2FB4341 
    # f30af495-61a6-49f5-a5de-d279d2fb4341
    
    vm_uuid = vm_uuid.upper()
    mydb = mysql.connector.connect(**mysql_config)
    mycursor = mydb.cursor()
    select_operation = "select sa_ip,business_ip from by_cmdb.asset_server where uuid='%s'" % vm_uuid
    mycursor.execute(select_operation)
    vm_ip_info = mycursor.fetchall()
    mycursor.close()
    mydb.close()
    if vm_ip_info:
        return vm_ip_info[0]
    else:
        return 0


# 通过ip从数据库中获取项目名
def get_p_name_from_ip(vm_sa_ip):
    
    mydb = mysql.connector.connect(**mysql_config)
    mycursor = mydb.cursor()
    select_operation = "select b.p_name from asset_server as a, asset_project as b where a.sa_ip='%s' and a.asset_project_id = b.id" % vm_sa_ip
    mycursor.execute(select_operation)
    vm_project_info = mycursor.fetchone()
    mycursor.close()
    mydb.close()
    if vm_project_info:
        return vm_project_info[0]
    else:
        return "none"




# 这个类是分析vm的xml，返回其中的一些内容，比如 mac地址信息
class vm_xml(object):

    def __init__(self, vm_xml_string):
        # 这个 vm_xml 是 xml 的字符串
        self.vm_xml_string = vm_xml_string
        self.vm_xml_obj = ElementTree.fromstring(self.vm_xml_string)

    def get_macs(self):
        """ 
        获取所有的mac地址信息
        {"type": "bridge",
        "source_bridge": "br0",
        "target_dev": "vnet2", # 这个暂时不收集
        "mac_address": "00:16:3e:e2:c9:0f"}
        """
        vm_macs = []
        vm_interfaces = self.vm_xml_obj.findall("devices/interface")
        for interface in vm_interfaces:
            if_type = interface.get("type")
            if_mac_address = interface.find("mac").get("address")
            if_source_bridge = ''
            if if_type == 'bridge':
                if_source_bridge =  interface.find("source").get("bridge")
            
            vm_macs.append({"type": if_type, "source_bridge": if_source_bridge,
                "mac_address": if_mac_address})
        
        return vm_macs

    def get_uuid(self):
        uuid_node = self.vm_xml_obj.find("uuid")
        if uuid_node:
            return uuid_node.text
    def get_name(self):
        name_node = self.vm_xml_obj.find("name")
        if name_node:
            return name_node.text

    def get_disks(self):
        """
        获取所有的disk信息
        {"driver_type": "qcow2", ""}
        """
        vm_disks = []
        vm_disk_nodes = self.vm_xml_obj.findall("devices/disk")
        for disk in vm_disk_nodes:
            # 这个有可能为空
            driver_type = ""
            source_pool = ""
            source_file_or_volume = ""
            disk_type = disk.get("type")
            # cdrom or disk
            disk_device = disk.get("device")
            driver_type = disk.find("driver").get("type")
            disk_source = disk.find("source")
            if disk_source is not None:
                source_pool = disk_source.get("pool")
                source_file_or_volume = disk_source.get(disk_type)

            target_dev = disk.find("target").get("dev")
            vm_disks.append({"driver_type": driver_type, "disk_type": disk_type,
                "disk_device": disk_device, "source_pool": source_pool, 
                "source_file_or_volume": source_file_or_volume, 
                "target_dev": target_dev})
        
        return vm_disks
    def get_vnc_info(self):
        #vnc_info = {}
        vnc_node = self.vm_xml_obj.find("devices/graphics")
        graph_vnc_port = vnc_node.get('port')
        return {"vnc_port": graph_vnc_port} 





# 获取 vm 的信息，将其整理成 cell 的数据文件格式，返回一个字典
#@pysnooper.snoop()
def get_dom_info(dom):
    dom_name = dom.name()
    dom_max_cpu = dom.maxVcpus()
    dom_max_memory = dom.maxMemory() * 1024
    dom_uuid = dom.UUIDString()
    # 获取第一块磁盘信息
    dom_xml_obj = vm_xml(dom.XMLDesc())
    dom_disks = dom_xml_obj.get_disks()
    # disk 大小,
    try:
        dom_vda_size = dom.blockInfo(path=vm_root_disk_t1)[0]
    except Exception as e:
        logging.error("The path=%s isn't exists, now try to other." % vm_root_disk_t1)
        dom_vda_size = dom.blockInfo(path=vm_root_disk_t2)[0]

    dom_vda_volume = "none"
    dom_vnc_port = 5901
    logging.debug("dom_disks: %s" % dom_disks)

    for d in dom_disks:
        # d 是 disk 的节点
        # In [108]: disk1_target.attributes.items()
        # Out[108]: [('dev', 'hda'), ('bus', 'ide')]
        logging.debug("d[target_dev]: %s" % d['target_dev'])
        if d['target_dev'] in vm_root_disks:
            dom_vda_volume = d['source_file_or_volume']

    # 磁盘信息，假设是获取带有 da 字样的磁盘信息, 还需要获取磁盘中的 ip 地址信息
    # 原先，只打算获取第一块网卡的 mac 地址就行了，现在因为要获取 ip 信息，
    # 要以mac地址去获取对应的ip, 在多网卡的环境下，不容易判断网卡是否是物理网卡
    # 在之前的 cloudstack 测试环境中，虚拟机中也有多块的虚拟网卡，所以这里需要判断一下是否有多个网卡
    # 根据目前的实际情况，一般情况下都是最多两个网卡

    dom_macs = dom_xml_obj.get_macs()
    # 为网卡2声明变量
    dom_interface2_mac = ''
    dom_interface2_br = ''
    # 获取mac地址
    dom_interface1_mac = dom_macs[0].get("mac_address")
    # 获取桥的名称，这个是物理机上的桥的名称
    dom_interface1_br = dom_macs[0].get("source_bridge")
    # 如果有超过一块网卡，就获取第二块网卡的信息，其他的不管
    if len(dom_macs) > 1:
        dom_interface2_mac = dom_macs[1].get("mac_address")
        dom_interface2_br = dom_macs[1].get("source_bridge")
    
    dom_vnc_port = dom_xml_obj.get_vnc_info().get("vnc_port")
    # 从数据库中获取ip信息
    # 当 vm 安装了 qga 之后，其 internal_address 自动生成，虽然在 cell 的数据文件中不显示
    # 如果 vm 没有安装 qga, 即使在数据文件中为其指定了 internal_address 在vm列表中也是不显示这个地址的，
    # 只在宿主机的详情页中的“内部地址”处显示
    # 外部地址在数据文件中即使有“external_address” 也是不显示的
    # 如果cell的数据文件中没有 internal_address ，在虚拟机关机后，在列表页和详情页都是看不到虚拟机的 ip 地址的
    # 如果 cell 的数据文件中有 internal_address, 在虚拟机关机后，在详情页中也是可以看到虚拟机的ip地址的

    # 经测试, 在已经获得了 vm 的 ip(静态) 之后，即使vm 关机了，在vm列表中仍然是显示这个 ip 的
    # 如果此时 cell 发生了重启，那么已关机的 vm 在 vm 列表中，就不再显示ip了
    dom_internal_ip = ""
    dom_external_ip = ""

    try:
        """
        如果网卡上有多个ip，那么理论上是按照顺序来排列的，也就是说第1个ip是真实的IP，
        这里 172.16.3.1 是vip
        type: 1  的是ipv6

        还需要考虑多块网卡的情况，像这台机器上还有虚拟网卡
        In [66]: v31.interfaceAddresses(source=1)['eth0']['addrs']
        Out[66]: 
        [{'addr': '10.6.36.187', 'prefix': 24, 'type': 0},
        {'addr': '172.16.3.1', 'prefix': 24, 'type': 0}]

        In [69]: v31.interfaceAddresses(source=1)['vnet8']
        Out[69]: 
        {'addrs': [{'addr': 'fe80::fc00:91ff:fe00:18', 'prefix': 64, 'type': 1}],
        'hwaddr': 'fe:00:91:00:00:18'}

        In [86]: v31_addrs
        Out[86]: 
        {'cloud0': {'addrs': [{'addr': '169.254.0.1', 'prefix': 16, 'type': 0},
        {'addr': 'fe80::28fe:a0ff:feaf:80e7', 'prefix': 64, 'type': 1}],
        'hwaddr': 'fe:00:a9:fe:59:86'},
        'cloudbr0': {'addrs': [{'addr': '10.6.36.187', 'prefix': 24, 'type': 0},
        {'addr': 'fe80::2820:d2ff:fee9:6bd0', 'prefix': 64, 'type': 1}],
        'hwaddr': '00:16:3e:47:c4:14'},
        'eth0': {'addrs': [{'addr': '10.6.36.187', 'prefix': 24, 'type': 0},
        {'addr': '172.16.3.1', 'prefix': 24, 'type': 0}],
        'hwaddr': '00:16:3e:47:c4:14'},
        'lo': {'addrs': [{'addr': '127.0.0.1', 'prefix': 8, 'type': 0},
        {'addr': '::1', 'prefix': 128, 'type': 1}],
        'hwaddr': '00:00:00:00:00:00'},
        'vnet0': {'addrs': [{'addr': 'fe80::fc00:aaff:fe00:22',
            'prefix': 64,
            'type': 1}],
        """
        dom_addrs = dom.interfaceAddresses(source=1)
    except Exception as e:
        logging.debug("%s.interfaceAddresses(source=1) failed." % dom.name(), e)
    else:
        for dom_addr in dom_addrs:
            if dom_addrs[dom_addr]['hwaddr'] == dom_interface1_mac:
                dom_internal_ip = dom_addrs[dom_addr]['addrs'][0]['addr']
                dom_internal_dev = dom_addr
            
            if dom_addrs[dom_addr]['hwaddr'] == dom_interface2_mac:
                dom_external_ip = dom_addrs[dom_addr]['addrs'][0]['addr']
                dom_external_dev = dom_addr

    # 如果没能从 interfaceAddresses() 的方法中获得ip地址,就尝试从数据库中获取
    if not dom_internal_ip:
        dom_ip = get_vm_ip_by_uuid(dom_uuid)
        if dom_ip:
            dom_internal_ip = dom_ip[0]
            dom_external_ip = dom_ip[1]

    # 获取vm的project_name
    dom_project_name = 'none'
    #dom_new_name = dom_name + '_' + dom_project_name
    dom_new_name = dom_name + '_' + dom_project_name
    if dom_internal_ip:
        dom_project_name = get_p_name_from_ip(dom_internal_ip)

    if dom_external_ip:
        # centos7_10-9-98-108_5913_none_10-8-98-208
        # centos7_10-9-98-108_5913_webset1_10-8-98-208
        #dom_new_name = dom_name.replace('.','-') + '_' + dom_project_name + "_" + dom_external_ip.replace('.','-')
        # 测试之后，决定不要原来的vm的名字，而直接采用 project_name_业务ip
        logging.debug("dom_name: %s, dom_project_name: %s, dom_external_ip: %s" % (dom_name, dom_project_name, dom_external_ip))
        # 这里 dom_project_name 可能是 0,即没有获取到有效的名字
        
        dom_new_name = dom_project_name + "_" + dom_external_ip.replace('.','-')
        

    dom_template = {"operating_system": "linux","disk": "sata",
        "network": "virtio","display": "vga","control": "vnc",
        "usb": "nec-xhci","tablet": "usb"}

    # 这个字典中，理论上，除了 create_time 之外，其他都可以更新
    dom_info = {"name": dom_new_name, "id": dom_uuid, "user": nano_user,
        "group": nano_group, "cores": dom_max_cpu, "memory": dom_max_memory,
        "disks": [dom_vda_size], "auto_start": True, "monitor_port": int(dom_vnc_port),
        "monitor_secret": "monitor_secret", "storage_mode": 0, "storage_pool": "local0", 
        "storage_volumes": [dom_vda_volume], "network_mode": 1, 
        "network_source": dom_interface1_br, "hardware_address": dom_interface1_mac,
        "auth_user": "root", "root_login_enabled": True, 
        "create_time": time.strftime("%Y-%m-%d %H:%M:%S"), 
        "internal_address": dom_internal_ip, "external_address": dom_external_ip,
        "cpu_priority": 1, "template": dom_template}

    return dom_info



# 停止或启动 nano-cell 服务的函数
def cell_svc_tool(state):
    if state not in ["start", "stop", "status", "restart"]:
        logging.error("please provide a arg like start or stop.")
        return False    
    
    logging.debug("systemctl %s nano-cell" % state)
    retcode = subprocess.call("systemctl %s nano-cell" % state, shell=True)
    if retcode == 0:
        return True
    else:
        return False

# 为 vm 进行改名的函数
def vm_rename(vm, vm_new_name, vm_finally_boot=True):
    # vm 是一个 libvirt 的 vm 对象， 可以进行 vm.rename() 操作
    # vm_new_name 是要修改的新的 vm 名称
    # vm_finally_boot 是指，改完名后，是否启动改名后的vm,默认为True
    if vm and vm_new_name:
        pass
    else:
        logging.ERROR("please provide both vm and vm_new_name.")
        return False
    
    # 先判断现有名字是否与新名字一致
    vm_now_name = vm.name()
    if vm_now_name == vm_new_name:
        return vm_now_name
    
    # 如果不一致，改名之前先备份 vm 的配置文件
    shutil.copy("/etc/libvirt/qemu/"+vm_now_name+".xml", nano_work_dir )
    # 判断vm是否运行
    # 执行关机操作
    # 在测试过程中，发现 centos7_10.9.98.109_5926 使用 vm.shutdown 无法关机成功
    # 这会导致脚本卡住一直循环下去，这是不行的
    # 需要定义一个超时时间，如果超过这个时间，那么就不再等待
    # 就暂时不对其进行关闭，也不再对其进行改名

    # 这里打算线上的不对其进行改名操作，而是跳过改名操作
    # 添加一个 hook, 等到虚拟机重启的时候，检查是否改名，没改的话，改掉
    if vm.isActive() == 1:
        logging.debug("The %s is running, now go to shutdown." % vm_now_name)
        logging.debug("skip vm.shutdown()")
        # 这里故意注释，不进行实际的关机操作
        #vm.shutdown()

    # 这里不会阻塞，所以手动进行阻塞
    shutdown_wait_time = shutdown_wait_second
    while shutdown_wait_time:
        if vm.isActive() == 1:
            time.sleep(1)
            shutdown_wait_time = shutdown_wait_time - 1
        else:
            break

     # 关机后，执行改名
    if vm.isActive() == 0:
        logging.debug("The %s is stopped, now call rename(%s)." % (vm_now_name, vm_new_name))
        vm.rename(vm_new_name)
    
    # 启动虚拟机
    # 这里竟然没有找到 libvirt 启动 vm 的方法

    if vm_finally_boot and vm.isActive() == 0:
        logging.debug("virsh start %s" % vm_new_name)
        subprocess.call("virsh start %s" % vm_new_name, shell=True)
    
    return vm_new_name

# 把 vm 信息写入 cell 数据文件的函数
def import_vm_to_nano(instance_data, vm):
    # vm 是一个 vm 对象
    #os.makedirs(nano_work_dir, exist_ok=True)
    subprocess.call("mkdir -p %s" % nano_work_dir, shell=True)
    vm_info = get_dom_info(vm)

    # 检测vm是不是已经有了 admin. 的前缀
    if vm_info['name'].split(".")[0] == "admin":
        # 如果说vm的名字中有 admin. 的字符串，那么需要进行检查
        pass
    else:
        # 这里说明vm的名字不带 admin. 的前缀
        # 其实他不带前缀也没关系，nano照样能识别
        # 备份原vm配置文件
        
        vm_new_name = 'admin.' + vm_info['name']
        vm_rename(vm, vm_new_name)
        vm_info['name'] = vm_new_name

        #write_instance_data_to_file(nano_cell_instance_data, vm_info)
        write_instance_data_to_dict(instance_data, vm_info)


# 这个是将数据写入 json 文件的
#def write_instance_data_to_file(json_file, vm_info):
    # json_file 是指json的文件，操作前会进行备份
def write_instance_data_to_dict(cell_instance_dict, vm_info):
    
    # vm_info 是指 vm 信息的字典，由 get_dom_info() 函数生成 

    # json_data 是要写入 json 中的实际数据，写入之前会进行判断，不存在则写入，
        # 存在但不一致，会更新，更新的话，有些数据需要忽略，比如 create_time这种, 这个就不太容易操作
    
    # 检测文件是否存在，存在则加载，不存在，则创建一个空文件
    # 这里每一个 vm 都会产生一次文件读写，暂时先这样吧
    """
    if os.path.exists(json_file) and os.path.isfile(json_file):
        with open(json_file, 'r') as cell_instance:
            cell_instance_dict = json.load(cell_instance)
    else:
        cell_instance_dict = {"instances": [], "storage_pool": "local0"}
        os.mknod(nano_cell_instance_data)
    """
    
    #json_file_suffix = '.' + str(os.getpid()) + time.strftime("%Y-%m-%d@%H:%M:%S~")
    # 这里仍然需要检查是否已存在于 cell data 文件
    for vm_instance in cell_instance_dict['instances']:
        if vm_instance['id'] == vm_info['id']:
            logging.debug("the %s already in cell data file." % vm_info['name'])
            # 如果id已经存在于文件中，则判断其是否需要更新
            # 因为 create_time 不需要更新，所以赋值为旧的时间
            vm_info['create_time'] = vm_instance['create_time']
            # 判断信息是否一致，不一致则更新
            if vm_instance != vm_info:
                #shutil.copy(json_file, 
                #    json_file + '.'+ vm_info['name'] + json_file_suffix)
                logging.debug("now, call %s.update(%s)" % (vm_instance['name'], vm_info))
                vm_instance.update(vm_info)
            
                # 写入json文件
                #with open(nano_cell_instance_data, 'w') as cell_instance:
                #    cell_instance.write(json.dumps(cell_instance_dict, indent=1))
            break
    else:
        # 改之前先备份
        #shutil.copy(json_file, 
        #    json_file + '.'  + vm_info['name'] + json_file_suffix)
        logging.debug("append %s to cell_instance_dict['instances']" % vm_info)
        cell_instance_dict['instances'].append(vm_info)

        # 写入json文件
        #with open(nano_cell_instance_data, 'w') as cell_instance:
        #    cell_instance.write(json.dumps(cell_instance_dict, indent=1))


# 这个是将网络数据写入 json 文件中
def write_network_data_to_file(json_file, vm_network_info):
    """
    {
    "default_bridge": "br0",
      "resources": {
        "96252b69-8d35-4e29-81de-8f18570acb19": {
            "monitor_port": 5942,
            "hardware_address": "00:16:3e:55:8d:d7",
            "internal_address": "",
            "external_address": ""
        }
      }
    }
    """
    pass



#dm = conn.lookupByID(2)
#print(get_dom_info(dm))
#import_vm_to_nano(dm)

#sys.exit(0)
#for dm in conn.listAllDomains():
# listDomainsID() 得到的是所有运行当中的虚拟机
def main():
    cell_svc_tool("stop")
    # 获取 instance 数据，或者初始化数据
    if os.path.exists(nano_cell_instance_data) and os.path.isfile(nano_cell_instance_data):
        with open(nano_cell_instance_data, 'r') as cell_instance:
            cell_instance_dict = json.load(cell_instance)
    else:
        cell_instance_dict = {"instances": [], "storage_pool": "local0"}
        os.mknod(nano_cell_instance_data)

    # 备份时的后缀名
    json_file_suffix = '.' + str(os.getpid()) + time.strftime("%Y-%m-%d@%H:%M:%S~")
    shutil.copy(nano_cell_instance_data, 
            nano_cell_instance_data + json_file_suffix)

    count = 0
    # 遍历所有运行当中的vm
    for dm_id in conn.listDomainsID():
        dm = conn.lookupByID(dm_id)
        # 执行添加或更新
        import_vm_to_nano(cell_instance_dict, dm)
        count = count + 1
        if count == 40:
            # 将修改后的 cell_instance_dict 写入文件
            logging.debug("write cell_instance_dict to %s" % nano_cell_instance_data)
            with open(nano_cell_instance_data, 'w') as cell_instance_w:
                cell_instance_w.write(json.dumps(cell_instance_dict, indent=1))
            cell_svc_tool("start")
            sys.exit(0)
    else:
        logging.debug("write cell_instance_dict to %s" % nano_cell_instance_data)
        with open(nano_cell_instance_data, 'w') as cell_instance_w:
            cell_instance_w.write(json.dumps(cell_instance_dict, indent=1))
        cell_svc_tool("start")

if __name__ == '__main__':
    main()

{%endraw%}
