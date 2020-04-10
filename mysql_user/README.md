# 介绍
role 的作用是创建或者更新mysql user的信息，并删除旧的用户。

```yaml
# group_vars/mysql.yml
mysql_app_users:
  - name: 'user1'
    password: '*929B1B59CC17E64096A78791831SSSSSSSSSSSSS'
    host: '192.168.%'
    priv: 'db1.*:ALL PRIVILEGES/db2.*:ALL PRIVILEGES'
    encrypted: True
  - name: 'user2'
    password: '*929B1B59CC17E64096A78791831SSSSSSSSSSSSS'
    host: '172.16.%'
    priv: 'db1.*:ALL PRIVILEGES/db2.*:ALL PRIVILEGES'
    encrypted: True


mysql_app_old_users:
  - name: 'user3'
    host: '192.168.%'
  - name: 'user4'
    host: '172.16.%'


# playbooks/mysql_user.yml
- hosts: mysql
  remote_user: root
  roles:
    - { role: mysql_user, mysql_sock: /data/apps/var/mysql-3306/mysql.sock, 
        mysql_login_user: root,
        mysql_login_pass: "mysqlpass"}

```

