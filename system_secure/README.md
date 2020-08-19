
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

- ntp_serve 指定 ntp 的地址
- 是否关闭透明大页，取决于 host 是否存在于 hadoop 的组中，或者定义 hadoop_yes: true, 否则会跳过关闭透明大页的操作

example:
```
- hosts: 10.111.32.209
  remote_user: geo
  roles:
    - {role: system_secure, system_ssh_pub_key: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDvV20+EMwX5yLV6aP3Qf+B2+Td4G7LTcKTp8VTln019F6bud0CEBQkMH9PZdY/G9kYUdCBQOSVx7IprnYjOXTy4MVQZNrZoWtQQfhjiXSVArUr7nAXEwaDh1MO0FXrfOVKgfvK0j9T/vfdXe2JfdPaKo9UarO1IomGWSIa/HWBsr10rqSYuD7JlCrN3jw+xtPVhadXyRLloiHyx740CkMnYLzOeGVxfzBn97PrRadga1ITzu5+D7i6qSsHJnthZGu6OUnnMBjVUJdf4/aiZgRmO+owTXmMXlsssssssssssssssssssssssBHphiK5Q+9oPeu7H root@localhost.localdomain", system_common_admin_pass: '$6$mysecretsalt$yf3du7J8hen0MG.nKFA6P8sm0nM1vrXEW.PQYDKNmz1./Xc5MczLax0KziVIstctdjgYYSamAVpYY04EW63y6.'}

```
