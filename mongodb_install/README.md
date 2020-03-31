# 说明
## 依赖项
* 此 role 依赖于 `common_boot_app common_copy_conf_file common_create_dir common_create_user common_packet_install`.
* 需要 cfssl, cfssljson 的命令行工具
* 需要提前下载 mongodb 的 tgz 文件,然后使用变量指定
* 配置文件需要自己写，可以参考 files 目录下的

## role 的操作
* 创建用户
* 创建目录
* 安装mongodb
* 复制配置文件
* 创建证书
* 复制证书
* 关闭THP
* 以非replicaset和非认证启动集群
* 配置文件中加入 replicaset 配置，重启,创建replicaset
* 配置文件中加入 net.tls 配置，重启

## 问题
2. `mongodb_` 开头的几个模块中的 ssl 选项都没有提供证书的参数，这不能适配新版本的 ssl 选项，因为当开启 ssl之后，想添加 shard, 只能手动设置了(当然可以写个脚本来实现)。 

* https://github.com/ansible/ansible/issues/66865 ： mongodb_replicaset: add sslCAFile and sslPEMKeyFile/tlsCAFile and tlsCertificateSelector options when ssl: yes (类似这样的问题还有很多)
* https://github.com/ansible/ansible/issues/19504 : mongodb_user always reports as changed (添加用户时总是返回 changed, 我也遇到了这个问题)


# 使用示例
## 定义组变量
```bash
[root@docker-182 group_vars]# cat mongo_237.yml 

mongo_packet: '{{packet_base_dir}}/mongodb-linux-x86_64-rhel70-4.2.2.tgz'

mongo_cert_hosts:
  - 127.0.0.1
  - localhost
  - 10.111.32.237
  - 10.111.32.238
  - 10.111.32.239
  - mongo237.test.com
  - mongo238.test.com
  - mongo239.test.com
```

* 安装一个 configsvr replicaset,名字为 configsvr
```yaml
- name: install mongodb
  hosts: mongo_237
  remote_user: user1
  roles:
    - { role: mongodb_install, mongo_conf_files: [configsvr.yaml], 
        mongo_primary_conf_file: configsvr.yaml,
        mongo_replica_conf_file: configsvr_replicaset.yaml,
        mongo_tls_conf_file: configsvr_net_tls.yaml,
        mongo_src_boot_file: mongodb-configsvr.service,
        mongo_instance_name: configsvr,
        mongo_port: "27019",
        mongo_admin_user: mongoroot,
        mongo_admin_password: 'myMONGO123',
        mongo_arbiter_at_index: null,
        #mongo_shards: ['shard1/10.111.32.237:22001,10.111.32.238:22001,10.111.32.239:22001']
        #mongo_shards: ['shard1/10.111.32.237:22001,10.111.32.238:22001,10.111.32.239:22001', 'shard2/10.111.32.237:22002,10.111.32.238:22002,10.111.32.239:22002']
        }

```

* 安装一个 shard replicaset 名字为 shard1
```yaml
- name: install mongodb
  hosts: mongo_237
  remote_user: user1
  roles:
    - { role: mongodb_install, mongo_conf_files: [shard1.yaml], 
        mongo_primary_conf_file: shard1.yaml,
        mongo_replica_conf_file: shard1_replicaset.yaml,
        mongo_tls_conf_file: shard1_net_tls.yaml,
        mongo_src_boot_file: mongodb-shard1.service,
        mongo_instance_name: shard1,
        mongo_port: "22001",
        mongo_admin_user: mongoroot,
        mongo_admin_password: 'myMONGO123',
        mongo_replicaset_members: ['10.111.32.237:22001', '10.111.32.238:22001', '10.111.32.239:22001']
        }
```
* 安装一个 mongos 集群
```yaml
- name: install mongodb
  hosts: mongo_237
  remote_user: user1
  roles:
    - { role: mongodb_install, mongo_conf_files: [mongos.yaml], 
        mongo_primary_conf_file: mongos.yaml,
        #mongo_replica_conf_file: mongos_replicaset.yaml,
        #mongo_tls_conf_file: mongos_net_tls.yaml,
        mongo_src_boot_file: mongodb-mongos.service,
        mongo_instance_name: mongos,
        mongo_port: "30000",
        mongo_admin_user: mongoroot,
        mongo_admin_password: 'myMONGO123',
        }
```
