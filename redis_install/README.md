# role 说明
* redis_install 的作用是安装 redis 的二进制文件，redis 需要提前编译好，并且相关命令须在 bin/ 目录下,打包为 tgz 格式。
* role 会创建相关目录，并启动 redis-server，修改 redis 所需要的内核参数并加入开机启动。 
* 相关的配置文件可以参考 templates 目录下

## redis 的编译示例
```bash
[root@docker-182 redis-5.0.8]# pwd
/data/apps/soft/ansible/redis/redis-5.0.8

[root@docker-182 redis-5.0.8]# make

# 对编译后的二进制进行测试，这个自已视情况要不要执行
[root@docker-182 redis-5.0.8]# make test 

[root@docker-182 redis-5.0.8]# make PREFIX=/data/apps/opt/redis-5.0.8 install

[root@docker-182 redis-5.0.8]# tar zcf redis-5.0.8_centos7_bin.tgz -C /data/apps/opt/ redis-5.0.8


```

## example:
```yaml
# 多实例部署:
# group_vars/redis.yml
redis_instances:
  - redis_port: 6395
    redis_service_name: 'redis_6395_svc1'
    redis_src_conf: './templates/redis.conf'
    redis_src_boot_conf: 'redis.ini'
    redis_requirepass: "123456"
    redis_master_pass: "123456"
    redis_master_server: "172.16.1.10"
    redis_master_port: '6395'
    redis_sentinel_name: "redis_svc1"
  - redis_port: 6396
    redis_service_name: 'redis_6396_svc2'
    redis_src_conf: './templates/redis.conf'
    redis_src_boot_conf: 'redis.ini'
    redis_requirepass: "123456"
    redis_master_pass: "123456"
    redis_master_server: "172.16.1.11"
    redis_master_port: 6396
    redis_sentinel_name: "redis_svc2"

# playbook
- hosts: redis
  remote_user: root
  roles:
    - { role: redis_install, 
        redis_packet: /data/apps/soft/ansible/redis-3.0.5.tgz, 
        redis_run_method: supervisor}


# 单实例部署时，变量示例如下, 如果 redis_instances 的变量不为空，那么下面的这些定义将会被忽略
redis_port: 6396
redis_service_name: 'redis_6396_svc3'
redis_src_conf: './templates/redis.conf'
redis_src_boot_conf: 'redis.ini'
redis_requirepass: "123456"
redis_master_pass: "123456"
redis_master_server: "172.16.1.12"
redis_master_port: 6396
redis_sentinel_name: "redis_svc3"


```

### 部署 redis_exporter
```ini
# redis_exporter/redis_exporter.ini
[program:{{redis_external_service_name}}]
command={{redis_base_dir}}/redis_exporter -export-client-list -redis.addr redis://127.0.0.1:{{redis_port}} -redis.password {{redis_requirepass}} -web.listen-address :{{redis_port | int + 10000 }}
directory={{redis_base_dir}}
user={{redis_run_user}}
priority=70
startsecs=10
autostart=true
autorestart=true
startretries=0
stopsignal=TERM
stopwaitsecs=5
redirect_stderr=false
stdout_logfile={{redis_log_dir}}/{{redis_service_name}}_exporter__std.log 
stdout_logfile_maxbytes=10MB  
stdout_logfile_backups=10    
stdout_capture_maxbytes=1MB  
stdout_events_enabled=false  
stderr_logfile={{redis_log_dir}}/{{redis_service_name}}_exporter_err.log
stderr_logfile_maxbytes=10MB   
stderr_logfile_backups=10     
stderr_capture_maxbytes=1MB  
stderr_events_enabled=false
```

```yaml
- hosts: redis
  roles:
  - {role: redis_install,
     redis_packet: /data/apps/soft/ansible/redis_exporter-v1.5.2.linux-amd64.tar.gz,
     redis_run_method: supervisor,
     redis_env_file: redis_exporter/redis_exporter.sh,
     redis_run_user: nobody,
     redis_app_name: redis_exporter,
     redis_src_conf: '',
     redis_sentinel_conf: '',
     redis_external_service_name: '{{redis_service_name}}_exporter',
     redis_restart_with_notify: true,
     redis_src_boot_conf: 'redis_exporter/redis_exporter.ini'}
```

## 注意事项
- 默认编译好的 redis-server 直接在 --prefix 目录下，这里需要放置在 prefis/bin/ 目录下
- `supervisor_conf_dir`, 这个参数是指定 supervisor 的配置目录的
- `redis_run_method`: 是配置 redis 运行方式的，system 代表使用系统服务方式，如centos6上的 sysv, centos7 上的 systemd, supervisor 就是使用 supervisor 来管理，建议使用后者
- redis.conf 中配置的内存为总内存的一半
- `redis_master_server`: 如果定义了这个变量，那么所部署的服务将是一个 slave, 与这个变量一起的变量还有 `redis_master_port`, `redis_master_pass`, 三个必须同时定义 
- `redis_restart_with_notify` redis 的配置文件或者 redis 进程的服务文件发生改变时，是否要重启，默认为不重启
- `redis_sentinel_conf` 此变量指定的是远程server 上的sentinel 配置文件，如果redis 与 sentinel 部署在同一台上，可以生成redis 的sentinel 配置


# 问题
* 目前只实现了 supervisor 控制redis的操作。
* redis 使用 sentinel 时，会修改自己的配置文件，所以在部署之后，如果再次同步配置文件，可能会出问题,这里后面可以尝试把本地配置文件，过滤出来相关配置使用 lineinfile 模块进行配置,即使这样慢，好在sentinel的基本配置并不多
