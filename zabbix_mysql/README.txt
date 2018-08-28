
# example:
## define host variables
```bash
[root@ansible host_vars]# pwd
/etc/ansible/host_vars
[root@ansible host_vars]# cat 192.168.1.10.yml 
---
mysql_basedir: /usr/local/mysql
mysql_datadir: /usr/local/mysql/data
mysql_User: root
mysql_Pass: 'mysql_pass'
mysql_sockPath: /var/lib/mysql/mysql.sock
``` 

## call playbook
```bash
- hosts: 
  remote_user: root
  roles:
    - { role: zabbix_mysql, 
        zabbix_conf_dir: /etc/zabbix/zabbix_agentd.d, 
        zabbix_script_dir: /etc/zabbix, 
        zabbix_service_name: zabbix-agent, 
        monitor_user: zabbix, 
        monitor_pass: "zabbix_123", 
        mysql_sockPath: /var/lib/mysql/mysql.sock, 
        mysql_datadir: /data2/mydata }
```
