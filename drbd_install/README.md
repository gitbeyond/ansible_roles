
这个role的作用是将编译好的 `keepalived` 部署到远程机器上,最简单的使用方式如下，其他默认变量参考 `defaults/main.yml`


```bash
- hosts: 10.111.32.61
  roles:
    - { role: keepalived_install,
        keepalived_packet: '{{packet_base_dir}}/keepalived-1.3.5_centos7_bin.tgz' }
```


## keepalived 的编译参数
```bash
./configure --prefix=/data/apps/opt/keepalived-1.3.5 --with-init=systemd

```

## keepalived 检测配置文件
高版本的 keepalived，如 2.0.11，已经有了检测配置文件的功能，应该使用这些版本。防止配置文件错误引起的不可用。

# 注意
1. 禁用系统的 drbd 服务，系统服务的脚本在有些情况下不适用，比如通过 keepalived 跟 drbd 结合做高可用时,都是使用 drbdadm 来切换drbd资源的状态，所以不需要启动drbd的服务
