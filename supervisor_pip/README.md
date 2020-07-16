# role 的作用
* 创建 supervisor 所需目录
* 安装 supervisor, 可以指定 net 或 local 方式，net 使用 pip 安装，local 方式会把指定的包复制到远程机器上使用pip进行安装
* 复制配置文件
* 复制服务配置文件
* 启动 supervisor


## net 安装方式
```yaml
# 这里强制收集fact是因为，supervisor 一般在机器准备使用的时候就会进行安装，随之安装的还有java环境
# 安装完java后，如果默认的 gathering = smart, 那么就会使用旧的 fact, 这样 supervisord.conf 中的一些模板就会匹配不到
# 运行时会有一些小问题
- hosts: 10.111.32.61
  remote_user: root
  gather_facts: true
  roles:
    - { role: supervisor_pip, 
        supervisor_log_dir: /data/apps/log/supervisord, 
        supervisor_var_dir: /data/apps/var/supervisord,
        supervisor_conf_dir: /data/apps/config/supervisord,
        supervisor_version: 4.1.0  }
```

## local 安装方式
```yaml
- hosts: 10.111.32.61
  remote_user: root
  gather_facts: true
  roles:
    - { role: supervisor_pip, 
        supervisor_log_dir: /data/apps/log/supervisord, 
        supervisor_var_dir: /data/apps/var/supervisord,
        supervisor_conf_dir: /data/apps/config/supervisord,
        supervisor_install_method: local,
        supervisor_packets: ['{{packet_base_dir}}/meld3-1.0.2.tar.gz', '{{packet_base_dir}}/supervisor-3.3.5.tar.gz']  }

```
