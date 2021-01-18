
此 role 的用途如下:
* 同步/etc/hosts 文件，默认以控制节点的为准
    * 同时根据 /etc/hosts 中的第一个名字，将其置为新的 hostname, 如 192.168.1.1 hadoop1.test.com hadoop1, 那么 192.168.1.1 的hostname 会成为 hadoop1.test.com
* 安装基础包,如 epel-release, htop, sysstat 等等
* 修改基础的内核参数
* 关闭ipv6
* 修改 limit 参数
* 添加 profile 
* 关闭 selinux
* 添加同步时间的计划任务,改为使用ntp或者 chrony
* 打开 rc-local service
* 关闭透明大页

- `ntp_server` 指定 ntp 的地址
- 是否关闭透明大页，取决于 host 是否存在于 hadoop 的组中，或者定义 `hadoop_yes: true`, 否则会跳过关闭透明大页的操作

example:
```
---
- hosts: 10.111.32.254
  remote_user: root
  roles:
   - { role: system_init, ntp_server: "cn.pool.ntp.org", hadoop_yes: true}
```
