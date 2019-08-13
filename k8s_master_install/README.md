
- name: install k8s_master
  hosts: k8s_125_master
  remote_user: root
  roles:
    - { role: k8s_master_install }
