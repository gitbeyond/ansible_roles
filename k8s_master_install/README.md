
# role 的说明
role 的作用是安装 k8s 的 master 节点（不含 etcd, etcd 需要使用 `etcd_install` 来完成）。安装方式是原生的二进制方式。

操作步骤如下:
* 创建工作目录及其下的子目录
* 生成证书所用到的json文件（这个是根据常用的进行生成的，可以自己进行覆盖或者跳过, 把相关的变量设置为自己想要的文件即可）
* 生成证书
* 生成 kubeconfig
* 安装 k8s master 的包
* 复制 k8s master 的配置文件
* 复制 k8s master service 的配置文件
* 启动 k8s master

## 依赖
1. cfssl, cfssljson, kubectl 的二进制文件，有相关变量可以进行配置
2. 证书的配置文件, 即 cfssl 生成证书时的 json 文件

## 注意
1. 没有为更改配置文件设置 notify, 重启操作需要手动进行
2. 此 role 用到的变量参考 defaults/main.yml


```bash
- name: install k8s_master
  hosts: k8s_125_master
  remote_user: root
  roles:
    - { role: k8s_master_install }
```
