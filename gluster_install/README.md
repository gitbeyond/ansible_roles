# role 说明
这个`role`的作用是部署一个`glusterfs`的集群。

目前仅支持使用`yum`来进行安装。





# examples

```ini
[k8s_56_gluster]
10.6.56.162
10.6.56.163
10.6.56.164

```

```yaml
- name: install gluster
  hosts: k8s_56_gluster
  roles:
    - role: gluster_install
```
