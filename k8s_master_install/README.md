
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
3. `k8s_work_dir` 写成相对路径时，执行 playbook 时须跟这个路径在同一级目录
4. `k8s_cert_dir` 指的是 `{{k8s_work_dir}}` 下面存放证书的目录，所以如果写成绝对路径时，一定要注意其在 `{{k8s_work_dir}}`目录内
5. `k8s_cert_json_dir` 与 `k8s_cert_dir` 一样，是存放证书 json 配置的目录




```yaml
# group_vars/k8s_master.yml
docker_packet: '{{packet_base_dir}}/docker-18.09.9.tar.gz'
docker_insecure_registry: 
  - 10.111.32.82:5000
  - 10.111.32.242

# etcd
etcd_run_port: "2379"
etcd_packet: '{{packet_base_dir}}/etcd-v3.4.7-linux-amd64.tar.gz'
etcd_initial_cluster_token: bj-170-k8s-etcd-cluster
etcd_member_endpoints: "{%for host in  groups['k8s_170_master']-%}
{{hostvars[host].etcd_name~'=https://'~host~':2380'-}}
{%if host != groups['k8s_170_master'][-1]-%}
,
{%-endif%}
{%-endfor%}"

etcd_client_endpoints: "{{ groups['k8s_170_master'] | map('regex_replace', '^(.*)$','https://\\1:'+etcd_run_port) | list |join(',')}}"

etcd_work_dir: etcd
etcd_cert_dir: ansible_etcd_certs
etcd_run_user: etcd

etcd_cert_hosts:
  - 127.0.0.1 
  - localhost
  - 10.111.32.170
  - 10.111.32.171
  - 10.111.32.172
  - bj-k8s-master-170.tmtgeo.com
  - bj-k8s-master-171.tmtgeo.com
  - bj-k8s-master-172.tmtgeo.com

# nginx
nginx_packet: '{{packet_base_dir}}/nginx-1.16.0_centos7_bin.tgz'
nginx_confs: "{{ q('fileglob', 'templates/nginx/*')}}"
nginx_child_confs: "{{ q('fileglob', 'templates/nginx/conf.d/*')}}"

# keepalived
keepalived_packet: '{{packet_base_dir}}/keepalived-1.3.5_centos7_bin.tgz'
keepalived_nginx_log: keepalived_nginx_state.log
keepalived_confs: "{{ q('fileglob', 'templates/keepalived/*') }}"

# k8s
k8s_kubectl_cmd: /root/k8s_55/kubectl
k8s_master_ha_vip: 10.111.32.173
k8s_master_ha_port: 7443
k8s_master_packet: '{{packet_base_dir}}/kubernetes/v1.16.5/kubernetes-server-linux-amd64.tar.gz'
k8s_run_user: kube
k8s_install_dir: /data/apps/opt/k8s_1.16.5
k8s_base_dir: /data/apps/opt/kubernetes
k8s_work_dir: k8s
k8s_cert_json_dir: certs_json
k8s_cert_dir: ansible_k8s_certs
k8s_master_local_conf_dir: "{{k8s_work_dir}}/ansible_k8s_confs"
k8s_master_service_confs:
  - "{{k8s_master_local_conf_dir}}/kube-apiserver.service"
  - "{{k8s_master_local_conf_dir}}/kube-controller-manager.service"
  - "{{k8s_master_local_conf_dir}}/kube-scheduler.service"


k8s_master_confs:
  - "{{k8s_master_local_conf_dir}}/kube-apiserver"
  - "{{k8s_master_local_conf_dir}}/kube-config"
  - "{{k8s_master_local_conf_dir}}/kube-controller-manager"
  - "{{k8s_master_local_conf_dir}}/kube-scheduler"
  - "{{k8s_master_local_conf_dir}}/kube-controller-manager.kubeconfig"
  - "{{k8s_master_local_conf_dir}}/kube-scheduler.kubeconfig"
  - "{{k8s_master_local_conf_dir}}/audit-policy.yaml"


k8s_kubelet_root_dir: /data1/apps/data/kubelet
k8s_node_packet: '{{packet_base_dir}}/kubernetes/v1.16.5/kubernetes-node-linux-amd64.tar.gz'
k8s_node_local_conf_dir: "{{k8s_work_dir}}/ansible_k8s_confs"
k8s_node_confs:
  - "{{k8s_master_local_conf_dir}}/kube-config"
  - "{{k8s_master_local_conf_dir}}/kubelet"
  - "{{k8s_master_local_conf_dir}}/kubelet.yaml"
  - "{{k8s_master_local_conf_dir}}/kube-proxy"
  - "{{k8s_master_local_conf_dir}}/kube-proxy.yaml"
  - "{{k8s_master_local_conf_dir}}/kube-proxy.kubeconfig"
  - "{{k8s_master_local_conf_dir}}/bootstrap.kubeconfig"
k8s_node_service_confs:
  - "{{k8s_node_local_conf_dir}}/kube-proxy.service"
  - "{{k8s_node_local_conf_dir}}/kubelet.service"

k8s_cert_hosts:
  - "127.0.0.1"
  - "10.254.0.1"
  - 10.111.32.165
  - 10.111.32.166
  - 10.111.32.168
  - 10.111.32.170
  - 10.111.32.171
  - 10.111.32.172
  - 10.111.32.173
  - bj-k8s-master-170.tmtgeo.com
  - bj-k8s-master-171.tmtgeo.com
  - bj-k8s-master-172.tmtgeo.com
  - bj-k8s-node-165.tmtgeo.com
  - bj-k8s-node-166.tmtgeo.com
  - bj-k8s-node-168.tmtgeo.com
  - "localhost"
  - "kubernetes"
  - "kubernetes.default"
  - "kubernetes.default.svc"
  - "kubernetes.default.svc.cluster"
  - "kubernetes.default.svc.cluster.local"


# playbook
- name: install k8s_master
  hosts: k8s_125_master
  remote_user: root
  roles:
    - { role: k8s_master_install }
```

# curl debug k8s
Bearer is the token of secret.
```bash
[root@nano-kvm-11 bloodsteel]# curl --cacert /tmp/k8s.ca  -H 'Authorization: Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6IkJjVE9JTVhQX0FuVnJ3ZFdTZ0FnQmh4RG1oLTJrMDRpSkxHQlJ6SjMxYVEifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJtb25pdG9yaW5nIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZWNyZXQubmFtZSI6ImlzdGlvLWV4cG9ydGVyLXRva2VuLWQ4cnRtIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6ImlzdGlvLWV4cG9ydGVyIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQudWlkIjoiYzUzN2QyODctZThlYy00ZjA4LThmYTAtZjVhOTdiYzhhZDA4Iiwic3ViIjoic3lzdGVtOnNlcnZpY2VhY2NvdW50Om1vbml0b3Jpbmc6aXN0aW8tZXhwb3J0ZXIifQ.JNFMV1oNUsJU30H9LXKX1wJ_gyGLgBKqSJ21lxqXBWSNV2lFtSij823uSgDW-y3aZmSkYXGswsbH3MEeZcqYJOEySg6AvpL4GvFIl6s3aFYJxrCn688fYeUgkbrlTErFClj_5INuDeN692mbvNOAz4KHWVTdc_9K6HjiOEZ0PKF35rxOmUGK1q-XlsTbQRGEbWP1DpAkaB6Sl-jPLdO_wy9AqN3m9N9DyyTpKhF2B7kBv1ZjxK3F97wQHcSJ48iH7IbWX0tB_nmxL4pfd5Fc7vsAZcmA6TmH3Pzrg4F5ngexUrFaTwbskj1OtHErNv_QCo7bXxwnGyTobOR0fc3HmA' https://10.6.56.10:7443/api/v1/namespaces?limit=500

```
