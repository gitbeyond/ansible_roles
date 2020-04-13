# role 的作用
1. 安装 percona-xtrabackup
2. 创建 mysql user
3. 复制备份脚本，添加备份的计划任务
4. 与远程机器配置免密通信，方便脚本把备份的数据发送至远程机器

example:
```yaml
# group_vars/mysql.yml
mysql_login_user: 'root'
mysql_login_pass: 'mysql_PAS_235'
mysql_sock: /data/apps/var/mysql/mysql.sock

mysql_backup_user: bkuser
mysql_backup_pass: 'mysql_bkUSER_pas2'
mysql_script_dir: /data/apps/opt/script/mysql
mysql_backup_weekday: 6
mysql_backup_hour: 3

mysql_binlog_backup_weekday: "0-5"
mysql_binlog_backup_hour: 3
mysql_backup_remote_host: 172.16.1.11
mysql_backup_remote_user: root

mysql_backup_host: 172.16.1.10
mysql_backup_num: 10

# playbooks
- hosts: mysql
  remote_user: root
  roles:
    - {role: mysql_backup}
```
