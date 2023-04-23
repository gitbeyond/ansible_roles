# lsyncd
是用来安装 lsyncd 的。同时可以为lsync配置文件中指定的rsync+ssh的远程主机，添加公钥。


> https://lsyncd.github.io/lsyncd/
> https://axkibe.github.io/lsyncd/manual/config/layer4/ : 2023/04/21 404


## examples

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

# reference
* https://mp.weixin.qq.com/s/QWNEIXMU4-nr3TF2B24Pvw : 文件实时同步神器lsyncd配置详解一
* https://mp.weixin.qq.com/s/OGSdN7lJaaE48Ef32hbSFw
* https://mp.weixin.qq.com/s/KTgPYqYHWlkrx-u97j9Nbw
* https://mp.weixin.qq.com/s/hqddlXdYAYzWa6omOMIX7g
* https://mp.weixin.qq.com/s/63OyvnxiWXXugLdRT4ovKw
