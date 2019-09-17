
这个role的作用是将编译好的 `nginx` 部署到远程机器上,最简单的使用方式如下，其他默认变量参考 `defaults/main.yml`


```bash
- hosts: 10.111.32.61
  remote_user: root
  roles:
    - { role: nginx_install,
        nginx_packet: /data/apps/soft/ansible/tengine-2.3.0_centos7_bin.tgz }
```
需要注意的几个变量
* nginx_confs: 这个是一个列表，包含了nginx的配置文件，dest_dir 都是 {{nginx_conf_dir}}这个目录，也就是说默认没有精细化的配置，安装后只是一个服务器，虚拟主机需要自己另行配置，默认包含 nginx.conf 和 htpasswd 这个 stub_status 模块的密码文件
* nginx_install_method: 如果值为 net,会使用  yum 安装一些依赖包，比如 geoip-devel, 如果是在没网的环境中，编译的时候，酌情开启一些模块，这样依赖少，可以至少保证正常工作，那时请将这个变量的值设为 local

