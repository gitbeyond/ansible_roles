---
- hosts: 172.16.9.77
  remote_user: root
  roles:
    - { role: mysql57_master, packet_dir: /root/wanghaifeng/, slave_mysql: 172.16.9.78, mysql_version: "5.7.18"}

- hosts: 172.16.9.78
  remote_user: root
  roles:
    - { role: mysql57_slave, packet_dir: /root/wanghaifeng/, master_mysql: 172.16.9.77, mysql_version: "5.7.18"}

