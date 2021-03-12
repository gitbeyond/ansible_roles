# This role 


example:

```yaml
---
- hosts: supervisor
  remote_user: root
  roles:
    - { role: zabbix_supervisor,
        zabbix_agent_base_dir: /usr/local/zabbix,
        zabbix_agent_conf: /usr/local/zabbix/etc/zabbix_agentd.conf,
        zabbix_agent_child_conf_dir: '/usr/local/zabbix/etc/zabbix_agentd.conf.d'
        zabbix_script_dir: /usr/local/zabbix/scripts }
```
