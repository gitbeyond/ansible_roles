# role 的作用是安装 nacos 集群

操作如下:
1. 创建用户
2. 创建目录
3. 安装 nacos
4. 复制配置文件
5. 复制nacos环境变量文件
5. 修改内核参数(暂未实现)
6. 启动 nacos


example:
```yaml

# playbook
- hosts: nacos_cluster
  remote_user: root
  roles:
    - role: nacos_install
      vars:
        nacos_packet: /data/apps/soft/ansible/nacos/nacos-server-1.3.1.tgz
        nacos_confs: 
          - templates/nacos/application.properties 
          - templates/nacos/cluster.conf
        nacos_use_mysql: false

```
