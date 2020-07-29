# 说明
* role 的目标是安装一个带流复制的 postgresql 服务
* 这个 role 暂时写到创建复制用户这里, 而且尚未进行过测试


## 计划完成的操作如下
* `postgresql_binary_install`
    * 创建运行用户
    * 创建目录
    * 安装包
    * 初始化数据目录 或 复制数据目录
        * 根据操作的不同需要考虑 slave 上是新建还是copy master 的数据
    * 复制配置文件
        * 默认情况下配置文件位于数据目录内，是否要修改为一个独自的目录是一个问题?
        * 根据help提示和搜索，没找到为 postgresql 单独指定配置文件的参数，暂时将其放到数据目录内吧
    * 复制服务文件
    * 启动服务
    * 创建用户，远程管理用户，复制用户等等
        * 目前远程管理用户尚未实现
        * 是否禁用默认的用户也是一个问题
    * 修改 hba 文件使创建的用户可以进行连接
    # 下面的未完成
    * slave 上是否需要 copy master 的原始数据，按照目前的预期是不需要的。需要实际测试
    * slave 上生成 recovery.conf 文件
    * slave 重启，开始进行复制

## 异步流复制的操作步骤
* 异步流复制的步骤
    1. 初始化数据目录
    2. 修改配置文件中关于复制的参数
        * wal_level = replica 有疑问，搜索的文档中是 wal_level = hot_standby
    3. 创建复制用户，并且允许用户从主/从都可以进行连接
    4. 使用 `select pg_start_backup();` 创建在线备份 
    5. 复制创建好的备份到从节点上
    6. 从节点配置 recovery.conf 恢复数据, 这里的参数也让人十分疑惑
        * `recovery_target_timeline` : 不理解, 执行备份命令的时候，如果还在写，那么最后生成的备份是怎么样的一种形式呢？
    9. 然后启动 pgsql 即可开始复制,(他这里还有一个 .pgpass 文件的过程，感觉这一步不需要吧)


* `pg_start_backup()` 的方式可以使用 `pg_basebackup` 工具来进行,


# 问题

## `pg_hba.conf` 如何管理的问题

这个配置文件，一是可以编辑好了，复制过去，二是可以使用 `postgresql_pg_hba` 模块现场修改，并生效。
如果二者配合使用的话，那么还得注意修改远程文件的时候，把本地的也修改了，要不将来一同步，远程的又成了
旧的了。

或者说不使用复制，只是现场修改，如何取舍，测试过后再决定吧。

pgsql 创建一个用户可能会生成多条 hba 记录，所以在编写 `postgresql_user` role 的时候，需要注意这个问题。



## 使用 systemd 来管理 pgsql

关于 `postgresql.service` 是从 `postgresql96-server-9.6.18-1PGDG.rhel7.x86_64` 包中获取的，并修改了相应的部分。

但是在启动时，却一直处于 `activating` 状态。

后来了解到这是由于 Type 的问题导致的，默认的Type为 `notify`, 与 Type=simple 相同，但约定服务会在就绪后向 systemd 发送一个信号。这一通知的实现由 libsystemd-daemon.so 提供。

改为 `simple` 后恢复正常，这是由于 rpm 包在编译时开启了systemd 相关的支持，所以使用 `notify` 是正常的，而自己下载的 tar.gz 的预编译包也许并未开启相关支持，导致其不能正常处理 `notify` 的相关操作。

后面可能还会有问题，先观察再说。
