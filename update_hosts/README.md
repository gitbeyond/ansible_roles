
# desc
根据文件或变量更新一组主机名。

`system_init`的role中有这一步操作，这个是为了方便单纯更新主机名的。
后面尝试，使用`include_role`的方式在`system_init`中导入。

```yaml
- hosts: k8s_56
  roles:
    - role: update_hosts
      vars:
        hosts_file: files/hosts
```

`hosts`，取第二列设置为主机名
```bash
# cat files/hosts 
10.6.56.99   k8s-master-56-99.by.com k8s-master-56-99
10.6.56.100    k8s-master-56-100.by.com k8s-master-56-100
10.6.36.100    k8s-master-36-100.by.com k8s-master-36-100
10.6.56.161    k8s-node-56-161.by.com k8s-node-56-161
10.6.56.162    k8s-node-56-162.by.com k8s-node-56-162
10.6.56.163    k8s-node-56-163.by.com k8s-node-56-163
```
