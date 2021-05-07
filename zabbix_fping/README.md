# example:

```yaml
---
- hosts: 10.111.32.237
  remote_user: root
  roles:
    - role: zabbix_fping
      vars:
        zabbix_conf_dir: /etc/zabbix/zabbix_agentd.d
        zabbix_script_dir: /etc/zabbix
        zabbix_service_name: zabbix-agent
```

# zabbix item prototypes

* icmppingloss[{#TARGETADDR}]
* icmppingsec[{#TARGETADDR},max]
* icmppingsec[{#TARGETADDR},avg]
* icmppingsec[{#TARGETADDR},min]
