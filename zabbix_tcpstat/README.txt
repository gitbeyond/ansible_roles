example:

---
- hosts: 10.111.32.237
  remote_user: root
  roles:
    - { role: zabbix_tcpstat, zabbix_conf.d_dir: /etc/zabbix/zabbix_agentd.d, zabbix_service_name: zabbix_agent }
