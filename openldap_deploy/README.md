# desc

`yum`方式部署`openldap`集群。

主要是在`CentOS`服务器上操作。


# openldap服务部署步骤

1. 安装openldap相关的软件
2. 进行基础配置
    * 修改“域名”
    * 设置管理员和密码
3. 

# 参考

1. https://www.golinuxcloud.com/install-and-configure-openldap-centos-7-linux/ : Step-by-Step Tutorial: Install and Configure OpenLDAP in CentOS 7 Linux
   1. 一个普通的基本的说明
2. https://www.digitalocean.com/community/tutorials/how-to-configure-openldap-and-perform-administrative-ldap-tasks  ：How To Configure OpenLDAP and Perform Administrative LDAP Tasks
3.  https://www.jianshu.com/p/b5df1eb1f4de ： CentOS上OpenLDAP Server使用cn=config方式配置
    1. 这里给出了直接编辑 cn=config目录下的文件的方式，修改配置的示例
   

# 问题

## 0728 发现

当天将`ansible`升级至`6.1.0`版本后，发现`ansible-doc -l`找不到原来的`ldap_entry`模块了。

搜索发现此模块是正常存在的`https://docs.ansible.com/ansible/latest/collections/community/general/ldap_entry_module.html`

此命令可以看到`community.general`这个`collection`。
```bash
ansible-galaxy collection list
```

也可以直接看此模块的文档
```bash
ansible-doc community.general.ldap_entry

```


