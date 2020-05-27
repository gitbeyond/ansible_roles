
此 role 的用途如下:
* 安装基础包,如 epel-release, htop, sysstat 等等
* 修改基础的内核参数
* 关闭ipv6
* 修改 limit 参数
* 添加 profile 
* 关闭 selinux
* 添加同步时间的计划任务
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
