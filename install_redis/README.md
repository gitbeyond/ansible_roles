# role 说明
install_redis 的作用是安装 redis 的二进制文件，redis 需要提前编译好，打包为 tgz 格式。
role 会创建相关目录，并启动 redis-server，修改 redis 所需要的内核参数并加入开机启动。 

## example:
```bash
- hosts: 172.16.1.2
  remote_user: root
  roles:
    - { role: install_redis, 
        app_packet: /root/wanghaifeng/redis-3.0.5.tgz, 
        install_dir: /data/apps/opt, 
        app_name: redis,
        app_port: 6379}
```

## 注意事项
- app_packet 解压后的目录名必须与 app_name 一致
