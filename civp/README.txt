---
- hosts: k8s_125_master
  remote_user: root
  roles:
    - { role: etcd_install}

