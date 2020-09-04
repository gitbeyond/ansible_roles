
* 需要在自己的 handlers 中 `listen: common_reload_app_conf`



# 问题

1. 此 role 使用的 handler 是 `common_app_restart` 和 `common_app_restart`，这两个 handler 默认存在于 `common_boot_app` role 当中。

如果一个 role 只引用了`common_copy_conf_file` 而未引用 `common_boot_app`,那么就会因为找不到 handler 而报错

2. 配置文件的触发可能需要触发 reload, 也可能需要触发 restart, 这个如何配置。

