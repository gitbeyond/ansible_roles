# 介绍
这个 role 的作用是将编译好的 mysql 复制至目标机器，并创建相关目录，最后启动mysql
关于 mysql 的初始化数据目录，这里的做法是将 mysql 初始化时的数据目录打包一份传至
目标机器，而不是在在目标机器上现场进行初始化。
这种做法更简洁一些。少了需要在目标机器初始化，并且获得随机密码再进行修改的操作。
前提是得有编译好的 **mysql二进制目录**和**初始化并修改了密码的数据目录**.

- 注意事项
  - mysql 的二进制压缩包解压后不能叫做 mysql, 可以是 mysql-5.7.24 这样，因为 role 会创建 mysql 的 link file
  - 数据目录压缩包同上
  - my.cnf 是配置文件，这个配置文件目前适用于 5.7 版本以内，在使用时应根据实际情况修改
  - mysql.init 是根据 5.7 中的启动文件进行修改的，其他版本还得确定是否可用
  - mysql 的包须是带父目录的
  - mysql_data_packet 的包须是不带父目录的

## 示例
```bash
---
- hosts: 172.16.1.1
  remote_user: root
  roles:
    - { role: mysql_binary_install, 
        mysql_packet: /usr/src/mysql-5.7.23-linux-glibc2.12-x86_64.tgz, 
        mysql_data_packet: /usr/src/mysql-5.7.23-datadir-initialize.tgz,
        mysql_port: 3307
      }
```
  
`/usr/src/mysql-5.7.23-datadir-initialize.tgz` 这个是在8.209上初始化后并修改了密码的数据目录.
```bash
mysql> set sql_log_bin=0;
Query OK, 0 rows affected (0.00 sec)

mysql> set password=PASSWORD('mysql_password');
Query OK, 0 rows affected, 1 warning (0.00 sec)
```
## 其他参数说明
mysql_slave_server: 指定一个IP,那么会创建一个以 mysync@ 命名的用户，用以复制，不指定会跳过
mysql_sync_pass: 指定复制用户的密码
mysql_sync_user: 

mysql_master_server: 指定 master 的IP，开始复制线程,这里的方式是使用GTID, auto_position=1, 不指定会跳过
mysql_sync_user: mysync
mysql_sync_pass: 'mySYNC-pass'


## 注意
1. 打包数据目录时，不要打包父目录，如 /data/apps/data/mysql 这个数据目录，要使用 `tar zcf -C /data/apps/data/mysql *` 来打包
2. 打包数据目录时，不要打包其中的 auto.cnf 文件,这个文件中包含了 mysql 的 UUID,每个server在启动时会自己生成。
