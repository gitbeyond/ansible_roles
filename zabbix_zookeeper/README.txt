example:

```bash
---
- hosts: zookeeper
  remote_user: root
  roles:
    - { role: zabbix_zookeeper,
        zabbix_dir: /usr/local/zabbix,
        zabbix_conf: /usr/local/zabbix/etc/zabbix_agentd.conf,
        zabbix_sender: /usr/local/zabbix/bin/zabbix_sender,
        zabbix_script_dir: /usr/local/zabbix/script }
```
