
# desc
根据文件或变量更新主机名。

`system_init`的role中有这一步操作，这个是为了方便单纯更新主机名的。
后面尝试，使用`include_role`的方式在`system_init`中导入。

```yaml
- hosts: k8s_56
  roles:
    - role: update_hosts
      vars:
        hosts_file: files/hosts
```
