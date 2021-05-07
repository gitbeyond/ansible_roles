# 2020/06/23 updated main.yml use import_tasks

针对安装方法和启动方法使用了 include_tasks 的单独 yml 文件，然后再在 main.yml 中进行 import


# 2021/02/20 增加在 CentOS6上安装python3.4的操作

supervisor-4.2.1 的版本至少需要 2.7 以上的版本

# 2021/03/23 supervisord 的 reload

1. supervisord 的 reload 操作会导致所有的 subprocess 重启, 虽然其自身的pid不变,非常危险!!! 
