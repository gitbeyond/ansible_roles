---
- hosts: 172.16.1.1
  remote_user: root
  roles:
    - { role: mysql57_master, packet_dir: /root/wanghaifeng/, slave_mysql: 172.16.1.2, mysql_version: "5.7.18"}

- hosts: 172.16.1.2
  remote_user: root
  roles:
    - { role: mysql57_slave, packet_dir: /root/wanghaifeng/, master_mysql: 172.16.1.1, mysql_version: "5.7.18"}

