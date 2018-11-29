example:

---
- hosts: elk6
  remote_user: root
  roles:
    - { role: zabbix_agentd, zabbix_service_name: zabbix-agent, zabbix_group: 'elk-server' }


```
    - { role: zabbix_agentd, zabbix_service_name: zabbix-agent, zabbix_group: ['elk-server','kafka'],host_templates: ['es', 'kafka'] }
```
