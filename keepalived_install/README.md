# desc
这个role的作用是将编译好的 `keepalived` 部署到远程机器上,最简单的使用方式如下，其他默认变量参考 `defaults/main.yml`


```bash
- hosts: 10.111.32.61
  roles:
    - { role: keepalived_install,
        keepalived_packet: '{{packet_base_dir}}/keepalived-1.3.5_centos7_bin.tgz' }

# or install keepalived by yum

- hosts: k8s_56_lvs
  roles:
    - role: keepalived_install
      vars:
        keepalived_confs: ['k8s_56_lvs/keepalived.conf']
        keepalived_install_method: net
```


## keepalived 的编译参数
```bash
./configure --prefix=/data/apps/opt/keepalived-1.3.5 --with-init=systemd

# or

./configure --prefix=/data/apps/opt/keepalived-2.1.5 --enable-log-file --with-init=systemd

# 具体可以 ./configure --help 查看

```

## keepalived 检测配置文件
高版本的 keepalived，如 2.0.11，已经有了检测配置文件的功能，应该使用这些版本。防止配置文件错误引起的不可用。

# 问题
1. 在 net_install 中使用了`include_vars: net.yml`,这种在指定 tags 时却加载不到了,导致复制出错。
