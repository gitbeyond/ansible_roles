
example:

```yaml
# 安装 jmx_exporter 的 jar 包，不启动，配置文件可以有多个
- hosts: 172.16.1.10
  remote_user: root
  roles:
    - { role: exporter_install, exporter_packet: /data/apps/soft/ansible/exporter/jmx_prometheus_javaagent-0.12.0.jar,
        exporter_run_user: root, 
        exporter_packet_type: jar,
        exporter_src_boot_file: '',  # 由于 exporter_install 可以部署多种 exporter, 所以为了防止其加载 group_vars 中的 exporter_src_boot_file, 要显示指定这个变量，如果没有，置为空字符串
        exporter_base_name: 'jmx_exporter', 
        exporter_install_dir: '{{app_base_dir}}/{{exporter_base_name}}',
        exporter_conf_files: ['jmx_exporter/tomcat_jmx.yml' ]}

# 安装 redis_exporter
- hosts: 172.16.1.10
  remote_user: root
  roles:
    - { role: exporter_install, 
        exporter_packet: /data/apps/soft/ansible/redis_exporter-v1.5.2.linux-amd64.tar.gz,
        exporter_run_user: nobody,
        exporter_packet_type: tgz,
        exporter_base_name: 'redis_exporter', 
        exporter_instance_name: 'redis_6389_exporter',
        redis_port: 6389,
        redis_requirepass: '123456',
        exporter_src_boot_file: redis_exporter/redis_exporter_1.ini,
        exporter_port: 16389  }
