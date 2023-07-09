
# role 的作用


## 操作步骤
* 创建工作目录
* 生成证书的 json 文件，变量见 `defaults/main.yml` ，其中 `etcd_cert_hosts` 没有默认值，需要显示配置。
	* 自行准备 `cfssl, cfssljson` 命令行工具，使用 `etcd_cfssl_cmd_path` 变量指定其路径
* 通过上述 `json` 文件,生成所需要的证书
* --- 以上是本地的操作
* 创建用户
* 创建目录
* 执行安装, 本地 rpm 包, 本地 binary 包，或者 yum(暂未实现)
* copy 配置文件
* copy 证书
* 启动 etcd
* 设置 etcdctl 的环境变量
* 添加备份的计划任务

# examples


## deploy a etcd cluster
```yaml
# inventory
[k8s_125_master]
172.16.1.1 etcd_name=etcd-1
172.16.1.2 etcd_name=etcd-2
172.16.1.3 etcd_name=etcd-3
# vars
script_deploy_dir: /opt/sh
etcd_install_dir: /opt/server
etcd_work_dir: '{{playbook_dir}}'
etcd_run_user: etcd
etcd_packet: "/data/apps/soft/ansible/etcd/etcd-v3.5.0-linux-amd64.tar.gz"
etcd_base_dir: /opt/server/etcd
etcd_data_dir: /opt/data/etcd
etcd_conf_dir: /opt/config/etcd
etcd_var_dir: /opt/var/etcd
etcd_log_dir: /opt/log/etcd
etcd_initial_cluster_token: 'pro-k8s-etcd'
etcd_member_endpoints: 'etcd-1=https://k8s-master-01.mydomain.com:2380,etcd-2=https://k8s-master-01.mydomain.com:2380,etcd-3=https://k8s-master-01.mydomain.com:2380'

etcd_backup_dir: /opt/data/backup/etcd
etcd_cert_valid_hour: '876000h'
etcd_cert_o: 'k8s'
etcd_cert_ou: 'system'
etcd_cert_hosts:
  - localhost
  - 127.0.0.1
  - 172.16.1.1
  - 172.16.1.2
  - 172.16.1.3
  - '*.mydomain.com'
etcd_cert_client_hosts:
  - localhost
  - 127.0.0.1
  - 172.16.1.1
  - 172.16.1.2
  - 172.16.1.3
  - '*.mydomain.com'

---
# playbook
- hosts: k8s_125_master
  remote_user: root
  roles:
    - { role: etcd_install}
```

## only generate certs
```bash
# ansible-playbook install_etcd.yml --tags="create_etcd_work_dir,generate_cert_confs,generate_certs"
```

# etcd的证书配置

以 `https://etcd.io/docs/v3.5/op-guide/clustering/` 为例，集群中应该有两份 ca 和 证书。
* 面向客户端的 ca 和证书
    * `--client-cert-auth --trusted-ca-file=/path/to/ca-client.crt`
    * `--cert-file=/path/to/infra2-client.crt --key-file=/path/to/infra2-client.key`
* 集群间节点的 ca 和证书
    * `--peer-client-cert-auth --peer-trusted-ca-file=ca-peer.crt`
	* `--peer-cert-file=/path/to/infra2-peer.crt --peer-key-file=/path/to/infra2-peer.key`

在示例当中，两个`ca`是不同的`ca`, 实际情况中当然是可以使用相同的`ca`证书的。


# 参考

* https://etcd.io/docs/v3.5/op-guide/configuration/ ： Configuration flags
