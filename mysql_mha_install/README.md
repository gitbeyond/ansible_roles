# role 的作用
1. 安装 `mha_manager` 需要指定 `mha_manager_host` 变量及 `mha_manager_packet` (包得提前自己下载好)
2. 安装 `mha_client`
3. 创建 mha 所需的 mysql 用户
3. 创建运行 `mha_client` 的用户，并且配置 `mha_manager` 与 `mha_client` 免密通信



```yaml
# group_vars/mysql.yml
mysql_mha_user: mha
mysql_mha_priv: '*.*:all'
mysql_mha_pass: 'dBa5AbLd28pDA5Ft9a1Veb8S9W5Ia4V7'
mysql_login_pass: MYSQLroot125
mysql_login_user: root
mysql_sock: /var/lib/mysql.sock
mysql_vip: 172.16.1.10

# 安装 mha-node
---
- hosts: mysql
  remote_user: root
  roles:
    - { role: mysql_mha_install,
        mha_client_packet: '{{packet_base_dir}}/mha4mysql-node-0.58-0.el7.centos.noarch.rpm',
        mha_manager_host: "172.16.1.126",
        mha_instance_name: "mha_mysql_svc1",
        mha_instance_src_conf: '{{file_base_dir}}/mha/mha_instance.conf'}

# 安装 mha-manager
- hosts: mysql
  remote_user: root
  roles:
    - { role: mysql_mha_install,
        mha_manager_packet: '{{packet_base_dir}}/mha4mysql-manager-0.58-0.el7.centos.noarch.rpm',
        mha_manager_host: "172.16.1.126"}

```

# 注意
1. 使用默认的`send_report` 文件时，需要定义如下的变量
```yaml
mha_mail_smtp: 'localhost'
mha_mail_from: 'mha_manager'
mha_mail_user: 'mha@localhost'
mha_mail_pass: '123456'
mha_mail_to:
  - root@localhost
```
2. 对于manager 及 node 的用户默认都是 root,这里暂时没有实现为其指定用户的操作,如果 node 的ssh用户不是root,需要配置sudo

# vip切换问题

arping -c 1 -U -I bond0  172.16.16.200

master_ip_failover这个脚本里加, 172.16.16.200是vip


```perl
sub start_vip() {  
`ssh $ssh_user\@$new_master_host \"  $ifctrl $ssh_start_vip \"`;  
`ssh $ssh_user\@$new_master_host \"  arping -c 1 -U -I bond0  172.16.16.200  \"`;  
} 
```
