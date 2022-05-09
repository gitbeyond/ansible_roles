
# role 的作用


## 操作步骤
* 创建工作目录
* 生成证书的 json 文件，变量见 `defaults/main.yml` ，其中 `etcd_cert_hosts` 没有默认值，需要显示配置。
* 通过上述 json 文件,生成所需要的证书
* 创建用户
* 创建目录
* 执行安装, 本地 rpm 包, 本地 binary 包，或者 yum(暂未实现)
* copy 配置文件
* copy 证书
* 启动 etcd
* 设置 etcdctl 的环境变量
* 添加备份的计划任务

```yaml
# vars



---
# playbook
- hosts: k8s_125_master
  remote_user: root
  roles:
    - { role: etcd_install}
```


# 参考

* https://etcd.io/docs/v3.5/op-guide/configuration/ ： Configuration flags