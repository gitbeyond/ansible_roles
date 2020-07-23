
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
