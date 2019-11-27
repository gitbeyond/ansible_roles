
- hosts: 10.111.32.162
  remote_user: root
  roles:
    - { role: exporter_install, exporter_packet: /data/apps/soft/ansible/jmx_prometheus_javaagent-0.12.0.jar,
        exporter_packet_type: jar, app_base_dir: /data/apps/opt/jmx_exporter,
        exporter_conf_file: [ '/data/apps/data/ansible/jmx_exporter/es_76/jmx_exporter_es.yml' ],
        exporter_run_user: root, 
        exporter_base_name: jmx_exporter,
        es_jmx_port: 9210 }

