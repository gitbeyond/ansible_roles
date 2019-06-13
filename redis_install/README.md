# role 说明
redis_install 的作用是安装 redis 的二进制文件，redis 需要提前编译好，并且相关命令须在 bin/ 目录下,打包为 tgz 格式。
role 会创建相关目录，并启动 redis-server，修改 redis 所需要的内核参数并加入开机启动。 

## example:
```bash
- hosts: 172.16.1.2
  remote_user: root
  roles:
    - { role: redis_install, 
        redis_packet: /data/apps/soft/ansible/redis-3.0.5.tgz, 
        redis_port: 6379,
        supervisor_conf_dir: /data/apps/config/supervisord}
```

## 注意事项
- 默认编译好的 redis-server 直接在 --prefix 目录下，这里需要放置在 prefis/bin/ 目录下
- supervisor_conf_dir, 这个参数是指定 supervisor 的配置目录的
- redis_run_method: 是配置 redis 运行方式的，system 代表使用系统服务方式，如centos6上的 sysv, centos7 上的 systemd, supervisor 就是使用 supervisor 来管理，建议使用后者
- redis.conf 中配置的内存为总内存的一半
- redis_master_server: 如果定义了这个变量，那么所部署的服务将是一个 slave, 与这个变量一起的变量还有 redis_master_port, redis_master_pass, 三个必须同时定义 
