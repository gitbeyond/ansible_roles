# desc

1. 安装 zabbix-agentd
2. 启动服务
3. 将 zabbix-agent 添加至 zabbix-server 当中

# examples

```yaml
---
- hosts: elk6
  remote_user: root
  roles:
    - { role: zabbix_agentd, zabbix_agent_svc_name: zabbix-agent, zabbix_groups: ['elk-server','kafka'], zabbix_host_templates: ['es', 'kafka'] }
```
