# role 的作用

* 创建 rabbitmq 用户
* 二进制安装 rabbitmq
* 复制配置文件
* 复制服务配置文件
* 指定一台 init node
    * 启动 rabbitmq
    * 获取 erlang cookie
* 将 cookie 同步至其他机器
* 将其他节点以 init node 为base加入集群
* 开启插件
* 添加虚拟机
* 添加用户
* 配置 policy


## example
```yaml
# vars/rabbitmq.yml
rabbitmq_vhosts:
  - name: /app1
  - name: /app2

rabbitmq_users:
  - user: app1
    password: app1_password
    permissions:
      - vhost: /app1
        configure_priv: .*
        read_priv: .*
        write_priv: .*
  - user: app2
    password: app2_password
    permissions:
      - vhost: /app2
        configure_priv: .*
        read_priv: .*
        write_priv: .*
  - user: app3
    password: app3_password
    permissions:
      - vhost: /app2
        configure_priv: .*
        read_priv: .*
        write_priv: .*
      - vhost: /app1
        configure_priv: .*
        read_priv: .*
        write_priv: .*
  - user: myadmin
    password: myadmin_pass
    tags: administrator
  - user: mymonitor
    password: mymonitor_pass
    tags: monitoring

# playbook
- hosts: rabbitmq_208
  vars_files:
    - vars/rabbitmq.yml
  roles:
    - {role: rabbitmq_install, rabbitmq_packet: '/data/apps/soft/ansible/rabbitmq/rabbitmq-server-generic-unix-3.8.7.tar.xz'}


```


# 注意
* 此 role 不安装 erlang，请使用别的 role 单独安装
* .erlang.cookie 默认在运行 rabbitmq 的用户的家目录下,此文件是一个长度为 20 的大写字母的文件(猜测)
    * 那么可以自己生成
    * 先在一个节点启动，启动完成后，将生成的 cookie 复制到别的节点 
* rpm 包安装的 rabbitmq,使用 rabbitmqctl 时有一个 chdir("/var/lib/rabbitmq") 的操作，而 tar 包安装的则没有这个操作(手动执行这个操作也不生效)

# 问题
* tar 包安装的 rabbitmq 使用 systemd 启动时有一些小问题，这种包里的没有实现 systemd 的 notify 机制
	* https://github.com/rabbitmq/rabbitmq-server/issues/664
* `rabbitmq_user` 有 bug, 使用的 permissions 参数进行设置的,其运行命令如下
```bash
# 这里的 vhost 是不存在的
/data/apps/opt/rabbitmq/sbin/rabbitmqctl -q -n '' clear_permissions -p vhost app3
```

## 配置文件问题

不设置 `log.file = rabbitmq.log`, 仅设置 `log.dir = {{rabbitmq_log_dir}}` 时，日志仍然不会在 log.dir 指定的目录下。
