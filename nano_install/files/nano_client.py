# -*- coding: utf-8 -*-
# editor: wanghaifeng@idstaff.com
# create date: 2021/01/19
# 首先提供一个 nano 的客户端，可以创建 vm
#
#

import requests
import json
import time
import pysnooper

user_list = ['zhangjiliang', 'qiyong', 'zhangguoqing', 'gutianyang', 'hujinhua', 'zhangrongrong', 'wanghaifeng', 'caizongye']
nano_users = [
]

for user in user_list:
    nano_users.append({"nick": user, "mail": user + '@idstaff.com', "password": user + '123A'})



class nano(object):
    api_root = '/api/v1'
    my_session_timeout = 0
    my_session_expire_time = 0
    my_session = ''

    def __init__(self, nano_user=None, nano_password=None,
                 nano_url='http://127.0.0.1:5870'):

        self.nano_user = nano_user
        self.nano_password = nano_password
        self.nano_url = nano_url
        self.nano_nonce = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
        self.session = ''

    def loginUser(self):
        self.nano_login_info = {
            "user": self.nano_user,
            "password": self.nano_password,
            "nonce": self.nano_nonce
        }
        self.login_data = requests.post(self.nano_url + nano.api_root + '/sessions/',
                                        data=json.dumps(self.nano_login_info))
        # 获得session对象的返回, text 是一个json串, json() 方法返回一个字典

        """
        {'error_code': 0,
        'message': '',
        'data': {'session': 'f242cb95-4d22-4523-9072-64f1b13e3dbc',
        'group': 'admin',
        'timeout': 180,
        'menu': ['media',
        'user',
        'visibility',
        'dashboard',
        'compute_pool',
        'image',
        'templates',
        'policies',
        'log',
        'address_pool',
        'storage_pool',
        'instance'],
        'address': '10.6.36.11'}}
        """
        return self.login_data

    @pysnooper.snoop()
    def nanoSession(self):
        # 如果没有session的话，获取session
        # if not nano.my_session:
        if not self.session:
            self.login_ret = self.loginUser().json()['data']
            self.session = self.login_ret['session']
            self.session_timeout = self.login_ret['timeout']
            self.session_expire_time = int(
                time.strftime("%s")) + self.session_timeout - 5
            return self.session

        if self.session:
            # 用当前的时间减去 seeeion_expire_time 看看是否过期
            session_use_time = int(time.strftime("%s")) - self.session_expire_time
            
            # 如果减的是正数，那么说明session过期了，重新获取
            if session_use_time > 0:
                self.nanoSession()
            else:
                return self.session

    def createVm(self, vm_info):
        self.session = self.nanoSession()
        self.header = {"Nano-Session": self.session,
                       "Content-Type": "application/json"}
        self.createVmApi = '/guests/'
        self.createVmRet = requests.post(self.nano_url + nano.api_root + self.createVmApi,
                                         headers=self.header, data=json.dumps(vm_info))
        # 创建成功后，会返回json,其中是vm的id
        # {'error_code': 0, 'message': '', 'data': {'id': '6f9d9500-eee2-4a39-83f2-d20fe21c12dc'}}
        return self.createVmRet.json()

    # 在 nano 中获得的 vm 的信息中并没有关于磁盘名称等信息
    # 只有 cell 指明了vm所有的宿主机

    # def getVmInfo(self, vm_id):
    def listUser(self):
        self.session = self.nanoSession()
        self.header = {"Nano-Session": self.session,
                       "Content-Type": "application/json"}
        self.listUserApi = '/users/'
        self.listUserRet = requests.get(
            self.nano_url + nano.api_root + self.listUserApi, headers=self.header)
        return self.listUserRet.json()

    def getUser(self, user_name):
        pass

    def createUser(self, user_info):
        """
        默认的api，只能创建用户,用户的组，需要再更改，这个需要参考下 gitlab 是怎么弄的
        {
        "nick": "AK",
        "mail": "a@b.com",
        "password": "abcdefg"
        }
        """
        self.session = self.nanoSession()
        self.header = {"Nano-Session": self.session,
                       "Content-Type": "application/json"}
        self.createUserApi = '/users/%s' % user_info['nick']
        self.createUserRet = requests.post(self.nano_url + nano.api_root + self.createUserApi,
                                           headers=self.header, data=json.dumps(user_info))
        #return self.createUserRet.text
        return self.createUserRet.json()


nano_url = 'http://10.6.36.11:5870'
nano_user = 'admin'
nano_password = 'Admin123'
na1 = nano(nano_user=nano_user, nano_password=nano_password, nano_url=nano_url)
# print(na1.loginUser())

h1 = {
    "name": "some_instance",
    "owner": "admin",
    "group": "admin",
    "pool": "default",
    "cores": 8,
    "memory": 8589934592,
    "disks": [64424509440],
    "auto_start": True,
    "system": "linux",
    "system_version": "CentOS 7",
    "template": "bvgqa6kmq5flt80mhk10",
    "from_image": "3c663540-b6c4-40f6-b151-590e72cccb1c",
    "modules": ["qemu", "cloud-init"],
    "cloud-init": {
        "root_enabled": True,
        "admin_name": "root",
        "admin_secret": "12345678",
        "data_path": "/opt/data"
    }
}

# print(na1.createVm(h1))
print(na1.listUser())

@pysnooper.snoop()
def test_create_user():
    user_create_ret = []
    for user in nano_users:
        user_create_ret.append(na1.createUser(user))

    print(user_create_ret)

test_create_user()
# 安装 libvirt ，在 sys.path 中增加其库路径
"""
[root@nano-kvm-11 config]# yum install python36-libvirt
In [1]: import sys

In [2]: sys.path
Out[2]: 
['/data/apps/opt/python3-gitlab/bin',
 '/usr/lib64/python36.zip',
 '/usr/lib64/python3.6',
 '/usr/lib64/python3.6/lib-dynload',
 '',
 '/data/apps/opt/python3-gitlab/lib64/python3.6/site-packages',
 '/data/apps/opt/python3-gitlab/lib/python3.6/site-packages',
 '/data/apps/opt/python3-gitlab/lib64/python3.6/site-packages/IPython/extensions',
 '/root/.ipython']

In [3]: sys.path.append('/usr/lib64/python3.6/site-packages')

In [4]: import libvirt

# 判断vm是否运行
dom1.isActive()

# 判断vm是否和配置文件是强联系的，也就是在shutdown之后他仍旧存在
In [59]: dom1.isPersistent()
Out[59]: 1

# 相当于 virsh dumpxml
dom1.XMLDesc() 
# 获取guest的cpu信息
dom1.guestVcpus()
{'vcpus': '0-7', 'online': '0-7', 'offlinable': '0-7'}
# 获取vm的名称
dom1.name()

# 获取uuid,就是vm的id
In [30]: dom1.UUIDString()
Out[30]: 'ec3bd69d-0a01-4005-9b42-5d0e6ceb4bb4'

# 由于vm的cpu和memory是可以在线调整的，所以使用max开头的方法是获取的其最大配置，由于线上的没有进行此项伸缩
# 配置，所以可以直接使用这两项，获取cpu及memory的配置
In [36]: dom1.maxVcpus()
Out[36]: 8

In [37]: dom1.maxMemory()
Out[37]: 16777216

# 这个方法可以方便的获取ip地址，但是如果没有安装 qemu-agent 的话，是不行的
>>> v5901.interfaceAddresses(source=1)
libvirt: QEMU Driver error : Guest agent is not responding: QEMU guest agent is not connected
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
  File "/usr/lib64/python2.7/site-packages/libvirt.py", line 1376, in interfaceAddresses
    if ret is None: raise libvirtError ('virDomainInterfaceAddresses() failed', dom=self)
libvirt.libvirtError: Guest agent is not responding: QEMU guest agent is not connected

"""
