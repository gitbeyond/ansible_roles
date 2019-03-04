example:

---
- hosts: 10.111.32.237
  remote_user: root
  roles:
    - { role: zabbix_mysql, zabbix_conf_dir: /etc/zabbix/zabbix_agentd.d, zabbix_script_dir: /etc/zabbix, zabbix_service_name: zabbix-agent, monitor_user: zabbix, monitor_pass: "zabbix_123", mysql_sock: /var/lib/mysql/mysql.sock, mysql_datadir: /data2/mydata }
