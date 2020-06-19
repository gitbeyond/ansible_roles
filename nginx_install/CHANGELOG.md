# 2020/06/18 重新整理各 task 的语法

* with_item 改为 loop
* 列表循环的地方，使用 default() 函数，减少了重复的代码
* 增加 nginx_systemd_file, nginx_boot_file, nginx_logrotate_file, nginx_env_file 等变量，方便可以自定义相关文件
* 增加了 nginx_other_confs 变量，用来指定 mime.types 等等辅助配置文件,默认的是只有4个,如果会用到 fastcgi.conf 等文件的话，自己修改变量即可

