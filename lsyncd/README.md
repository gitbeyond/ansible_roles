# lsyncd
是用来安装 lsyncd 的。同时可以为lsync配置文件中指定的rsync+ssh的远程主机，添加公钥。


> https://axkibe.github.io/lsyncd/manual/config/layer4/

examples:
```yaml
---
- hosts: jenkins_server
  roles:
    - { role: lsyncd, 
        lsyncd_conf_files: ['lsyncd.conf']}


---
- hosts: 172.16.9.7
  remote_user: root
  roles:
    - { role: lsyncd, 
        lsyncd_conf_files: ['lsyncd.conf'],
        backup_remote_host: '172.16.7.5' }
```
