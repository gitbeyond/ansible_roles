```bash
---
- hosts: 10.111.32.61
  remote_user: root
  roles:
    - { role: supervisor_pip, 
        supervisor_log_dir: /data/apps/log/supervisord, 
        supervisor_var_dir: /data/apps/var/supervisord,
        supervisor_conf_dir: /data/apps/config/supervisord,
        supervisor_version: 3.3.5  }
```

or
```bash
- hosts: 10.111.32.61
  remote_user: root
  roles:
    - { role: supervisor_pip, 
        supervisor_log_dir: /data/apps/log/supervisord, 
        supervisor_var_dir: /data/apps/var/supervisord,
        supervisor_conf_dir: /data/apps/config/supervisord,
        supervisor_install_method: local,
        supervisor_packets: ['{{packet_base_dir}}/meld3-1.0.2.tar.gz', '{{packet_base_dir}}/supervisor-3.3.5.tar.gz']  }

```
