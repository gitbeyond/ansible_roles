# desc

1. 部署一个`tar.gz`的的`maven`
2. 添加环境变量 (可选)
3. 添加配置文件 (可选)



# examples

```yaml
# vars

- hosts: 10.111.111.110
  remote_user: root
  roles:
    - { role: maven_install, maven_packet: /data/apps/soft/ansible/apache-maven-3.5.4-bin.tar.gz }
```
