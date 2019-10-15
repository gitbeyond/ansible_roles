
# role 说明
role 的作用是安装 filebeat, 同步 filebeat 的配置文件
# 使用
* 得有一个 filebeat 的安装包，如 `filebeat-7.4.0-linux-x86_64.tar.gz`, 必须是 tar.gz 的包
* 配置 host或 group 的变量，变量见 `defaults/main.yml`
* 运行 playbook, 如
```bash
---
- name: install filebeat
  hosts: 172.16.1.1
  remote_user: root
  roles:
    - { role: filebeat_install}
```
