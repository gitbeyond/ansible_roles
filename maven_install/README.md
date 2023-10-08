# desc

1. 部署一个`tar.gz`的`maven`
2. 添加环境变量 (可选)
3. 添加配置文件 (可选)
4. 添加额外的配置文件 (optional)



# examples

```yaml
# vars

- hosts: 10.111.111.110
  remote_user: root
  roles:
    - role: maven_install
      maven_packet: /data/apps/soft/ansible/apache-maven-3.5.4-bin.tar.gz

---
- hosts: 192.168.1.1
  roles:
    - role: maven_install
      maven_app_name: 'maven-3.5'
      maven_install_dir: '/opt/tools'
      maven_packet: /data/apps/soft/ansible/maven/apache-maven-3.5.4-bin.tar.gz
      maven_profile: ''
      maven_extra_conf_dir: '/opt/conf/{{maven_app_name}}'
      maven_extra_confs:
        - files/deploy_mvn_settings.xml
        - files/dev_mvn_settings.xml
        - files/qa_mvn_settings.xml

```


