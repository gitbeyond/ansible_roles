
这个 role 的作用是安装 zk
```yaml
- hosts: oldcivp9_zookeeper
  remote_user: root
  roles:
    - { role: zookeeper_install, zookeeper_packet: /data/apps/soft/ansible/zookeeper-3.4.8.tar.gz,
        zookeeper_conf_file: [ '{{file_base_dir}}/oldcivp9/zookeeper/zoo.cfg', '{{file_base_dir}}/oldcivp9/zookeeper/java.env',
        '{{file_base_dir}}/oldcivp9/zookeeper/zookeeper_jmx.yml' ],
        zookeeper_boot_file: '{{file_base_dir}}/oldcivp9/zookeeper/zookeeper.ini', 
        zookeeper_run_user: zookeeper,
        zookeeper_base_name: zookeeper,
        zookeeper_jmx_port: 2190}
```
