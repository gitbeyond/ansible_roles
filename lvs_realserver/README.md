```yaml
- hosts: 10.111.111.110
  remote_user: root
  roles:
    - { role: lvs_realserver, lvs_vip: 10.111.20.253}
```

or 

```yaml
- hosts: 10.111.111.110
  remote_user: root
  roles:
    - { role: lvs_realserver, lvs_vip: 10.111.20.253, lvs_realserver_generate_metrics: false}

# updated vip
- hosts: 10.111.111.110
  remote_user: root
  roles:
    - { role: lvs_realserver, lvs_vip: 10.111.20.253, lvs_old_vip: 10.111.20.252}
```
