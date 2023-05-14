download node package:
```bash
# wget https://nodejs.org/download/release/v14.17.6/node-v14.17.6-linux-x64.tar.gz
```

example:
```yaml
- hosts: 10.111.111.110
  remote_user: root
  roles:
    - { role: nodejs_install, nodejs_packet: /data/apps/soft/ansible/node-v14.15.1-linux-x64.tar.xz }
```
