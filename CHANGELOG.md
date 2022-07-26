# 2022/04/21

## update system_user_init

* `lineinfile`换为`community.general.sudoers`
    * 由于变量原因，暂未能换成
* `lineinfile`换为`ansible.posix.authorized_key`
* 添加`pam_access`的配置
* 为用户添加单独的`user_pub_key`配置，每个用户可以有专用的公钥

sudoers模块测试效果如下
```bash
# ansible 10.6.36.13 -m community.general.sudoers -a "name='test' user='nginx' commands=ANY"


# ls /etc/sudoers.d/
test
# cat /etc/sudoers.d/test 
nginx ALL=NOPASSWD: ANY


```

##