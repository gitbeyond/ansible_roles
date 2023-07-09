
# role 的作用
role 的作用是安装 k8s 的 node 节点。安装方式是原生的二进制方式。

操作步骤如下:
* 生成 token 和 bootstrap.kubeconfig 
* 安装 k8s node 二进制包
* 复制 kubelet 和 kube-proxy 配置文件
* 复制其服务启动配置文件
* 在集群中创建生成的 bootstrap token 和 rolebinding 


## 注意
1. 没有为更改配置文件设置 notify, 重启操作需要手动进行
2. 此 role 用到的变量参考 defaults/main.yml 
3. 依赖 kubectl 命令，有变量设置此，一般来说，都是先使用 `k8s_master_install` 这个 role, 再使用这个 role 安装 node 节点，所以与 `k8s_master_install` 共享多个变量
4. 之所以在这时创建 bootstrap token, 是因为写的时候没注意这个问题，后面把创建 token 的操作移到 `k8s_master_install` 中


# 依赖准备
# examples

```yaml
- name: install k8s_master
  hosts: pro_k8s_master
  roles:
    - role: k8s_node_install
```


# kubelet 的证书

为`kubelet`指定如下参数后，测试访问
* tlsCertFile: /etc/kubernetes/ssl/k8s-kubelet.pem
* tlsPrivateKeyFile: /etc/kubernetes/ssl/k8s-kubelet-key.pem

```bash
# curl --cacert /etc/kubernetes/ssl/k8s-root-ca.pem --cert /etc/kubernetes/ssl/k8s-kube-apiserver-kubelet-client.pem --key /etc/kubernetes/ssl/k8s-kube-apiserver-kubelet-client-key.pem https://k8s-master-01.mydomain.com:10250/metrics

```

# 参考

* https://kubernetes.io/zh/docs/reference/config-api/kubelet-config.v1beta1/ : Kubelet 配置 (v1beta1)
