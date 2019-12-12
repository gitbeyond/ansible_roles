
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
