# role 的作用是安装 skywalking 集群

操作如下:
1. 创建用户
2. 创建目录
3. 安装 skywalking
4. 复制配置文件
5. 修改内核参数
6. 启动 elasticsearch


example:
```yaml
# group_vars/sw_hosts.yml

sw_packet: /data/apps/soft/ansible/skywalking/apache-skywalking-apm-es7-8.5.0.tar.gz
sw_service_type: systemd
sw_env_vars:
  SW_JDBC_URL: "jdbc:mysql://10.0.0.213:3307/swtest"
  SW_DATA_SOURCE_USER: "swtest"
  SW_DATA_SOURCE_PASSWORD: "swtest123"
  OAP_LOG_DIR: "{{sw_log_dir}}"
  SW_STORAGE: "mysql"
  JAVA_OPTS: "-Xms2048M -Xmx2048M"
  SW_RECEIVER_ZIPKIN: "default"
  PATH: "{{ansible_env['PATH']}}"

sw_webapp_env_vars:
  WEBAPP_LOG_DIR: '{{sw_log_dir}}'
  JAVA_OPTS: "-Xms2048M -Xmx2048M"
  PATH: "{{ansible_env['PATH']}}"

# playbook
- hosts: sw_hosts
  remote_user: root
  roles:
    - { role: skywalking_install }
# or
- hosts: localhost
  roles:
    - role: skywalking_install

```

# issues


## 包名问题
skywalking包的目录问题，默认的skywalking解压后的包，不带版本信息。
```bash
[root@VM-0-3-centos skywalking]# ll
total 180496
drwxrwxr-x 11 jenkins jenkins      4096 Jun  9 15:32 apache-skywalking-apm-bin-es7
-rw-r--r--  1 root    root    184816700 Apr  9 23:46 apache-skywalking-apm-es7-8.5.0.tar.gz
```

如果以后再来一个`8.6.0`的包，解压后仍然是`apache-skywalking-apm-bin-es7`,使用本role当前的操作,就不会更新了(`creates参数导致的`)。

所以可以简单的使用`sw_packet_dir_name: "{{sw_packet.replace('.tar.gz','') |basename}}"`来当做安装的dirname,不过这种，导致整个操作都要随之而变，所以这里不使用此方法。

也就是说，需要手动的重新打成带版本号的`tar.gz`包。
```bash
[root@VM-0-3-centos skywalking]# mv apache-skywalking-apm-bin-es7 apache-skywalking-apm-es7-8.5.0
[root@VM-0-3-centos skywalking]# tar zcf apache-skywalking-apm-es7-8.5.0.tgz apache-skywalking-apm-es7-8.5.0

``` 
## 启动脚本问题
1. 默认的启动脚本只能运行在后台，这个就不能使用supervisor来管理，所以为其编写了systemd的配置文件；
2. 同时尝试性地为skywalking提交了pr,在其启动脚本中添加了`start-daemon`和`start-foreground`参数；
    * 如果其合并了，那么还要修改现在的supervisor和systemd的配置文件；

## agent设置oap服务器地址问题

* https://github.com/apache/skywalking/issues/3159 : about OAP cluster setup #3159

## 日志滚动问题

### oap
* /data/apps/log/skywalking/oap.log , 不滚动, 量不大
* /data/apps/log/skywalking/skywalking-oap-server.log , 这个是主要增长
* /home/sw/logs/nacos/config.log， 量不大，只在某些情况下才会滚动，配置文件中没有相应的配置条目
    * config.log.2022-01-25.1
    * config.log.2021-12-02.1
* /home/sw/logs/nacos/naming.log
    * naming.log.2021-12-25.1
    * naming.log.2022-01-03.1

### webapp
这两个都是在脚本中指定的，并没有明确的参数可以配置其滚动，目前其量不大，可以暂时就这样。后面可以修改脚本，为日志文件加上时间信息，定期重启实现滚动操作。

* /data/apps/log/skywalking/webapp-console.log
* /data/apps/log/skywalking/webapp.log 


