example:
```yaml
- hosts: 10.111.111.110
  remote_user: root
  roles:
    - { role: jdk_install, jdk_packet: /data/apps/soft/ansible/jdk1.7.0_67.tar.gz }
```
