
# role 的作用 

## 这个 role 的作用是安装一个 zk 集群.
* 创建用户
* 创建目录
* 安装 zk 的 tar.gz 包
* 复制配置文件
    * 默认的配置文件使用 templates 之内的，启动时会指定 ZOOCFGDIR 变量，并且配置了 java.env, 会监听jmx 端口。
    * 依赖 `jmx_exporter` 需要先安装这个 `jmx_exporter`，也可以自定义配置文件，不使用这个组件
* 启动 zookeeper, 目前只支持 supervisor 的启动方式


```yaml

- hosts: zookeeper
  roles:
    - { role: exporter_install, exporter_packet: /data/apps/soft/ansible/jmx_prometheus_javaagent-0.12.0.jar,
        exporter_run_user: root, 
        exporter_packet_type: jar,
        exporter_install_dir: '{{app_base_dir}}/{{exporter_base_name}}',
        exporter_base_name: 'jmx_exporter', 
        exporter_conf_files: ['jmx_exporter/tomcat_jmx.yml' ] }
    - { role: zookeeper_install, zookeeper_packet: /data/apps/soft/ansible/zookeeper-3.4.8.tar.gz,
        zookeeper_conf_files: [ '{{file_base_dir}}/zookeeper/zoo.cfg', '{{file_base_dir}}/zookeeper/java.env',
        '{{file_base_dir}}/zookeeper/zookeeper_jmx.yml' ],
        zookeeper_boot_file: '{{file_base_dir}}/oldcivp9/zookeeper/zookeeper.ini', 
        zookeeper_run_user: zookeeper,
        zookeeper_base_name: zookeeper,
        zookeeper_jmx_port: 2190,
        jmx_exporter_base_dir: /data/apps/opt/jmx_exporter}
# or 
- hosts: zookeeper
  roles:
    - { role: exporter_install, exporter_packet: /data/apps/soft/ansible/jmx_prometheus_javaagent-0.12.0.jar,
        exporter_run_user: root, 
        exporter_packet_type: jar,
        exporter_install_dir: '{{app_base_dir}}/{{exporter_base_name}}',
        exporter_base_name: 'jmx_exporter', 
        exporter_conf_files: ['jmx_exporter/tomcat_jmx.yml' ] }
    - { role: zookeeper_install, zookeeper_packet: /data/apps/soft/ansible/zookeeper-3.4.8.tar.gz,
        jmx_exporter_base_dir: /data/apps/opt/jmx_exporter}
```

# CHANGELOG
## 2020/06/29
`zookeeper_conf_file` 变为 `zookeeper_conf_files`, 如果配置文件只有一个，可以使用 `zookeeper_conf_file`
