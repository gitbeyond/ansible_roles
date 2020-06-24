# role 的作用

* 创建一个普通用户,为其配置 sudo 权限
* 将 ansible 控制节点的公钥添加至用户的 `authorized_keys` 文件中
* 更新root的默认密码，如果提供新密码的话(这个密码不需要太复杂，比如 e3B1bEeAb0E9Ld8wV2Uf7GfE9Z6FfM1B, 因为 root 会被禁止ssh登录，密码会用来登录控制台)
* ssh 配置中禁止root登录，重启 sshd


# role 的使用

declare vars:
```yaml
# 定义在这个列表当中
system_admin_users:
  - user:
    password:
    sudo_priv:   # sudo 的权限配置
    copy_pub_key: # 是否复制ansible控制节点的公钥至此用户的配置当中, 普通用户，一般不会配置 sudo_priv 权限，默认不复制
```

example:
```yaml
# group_vars or other var define
system_users:
  - user: admin
    password: 'encrypted_password'
    sudo_priv: 'admin ALL =(ALL) NOPASSWD: ALL'
    copy_pub_key: True # 定义了 sudo_priv 的情况下，这个变量默认为True
  - user: elk
    password: 'elk_encrypted_password'
    copy_pub_key: True
  - user: grafana
    password: 'grafana_encrypted_password'

system_admin_user: admin # 在禁止root用户登录的时候会用到这个用户,默认是 system_users 中的第一个用户
#system_ansible_pub_key: 'ansible_control_host_public_key'
system_ansible_pub_key: '{{ lookup('file', '/path/to/id_rsa.pub') }}'


# playbook
hosts: myhosts
roles:
  - {role: system_user_init}

```
