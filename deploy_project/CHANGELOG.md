

# 2020/06/09 add project_nginx_confs variable

添加如下变量，应对项目的多样性，比如 xxl-job-admin 部署之后，会有一个nginx的配置文件，此时单独为其再弄一个 playbook 有些麻烦，所以可以指定一个变来应对这种操作。

同时还添加了 project_conf_file 变量，这个变量默认会被 copy 到 `{{project_conf_dir}}`

新加的变量如下:
* project_nginx_conf: 单个配置文件时用这个
* project_nginx_confs: 多个配置文件时用这个列表
* project_conf_file: 尚未添加相关操作
* project_conf_files

# 2020/06/10 add project_nginx_server variable

添加 `project_nginx_server` 来应对项目的机器与 nginx 机器不一致的情况。

如部署服务到 `server_group1` 而 nginx 却在 `nginx_server` 上。

# 2020/06/11 add project_proxy_nginx_server variable

`project_nginx_server` 的名称有些不太明确，因此改为 `project_proxy_nginx_server`, 并将 `project_nginx_conf` 改为 `project_proxy_nginx_conf`


* project_proxy_nginx_conf: 项目中需要为其配置 nginx 代理的配置文件,这个文件不是复制至目标主机，而是需要 delegate_to 别的 nginx 主机
* project_proxy_nginx_confs: 列表形式

* project_proxy_nginx_server: delegate_to 的主机组,即使只有一台，也应该写成列表，因为这里要进行循环, 默认使用当前目标主机组
    * 自己指定时可写成 `{{ groups["nginx_server"] }}`
* project_proxy_nginx_remote_user: delegate_to 的主机的用户，有可能其与目标主机使用的是不同的 remote_user

## 与此相关的问题
* 在 `main.yml` 中为 `include_tasks` 使用 delegate_to 是不可以的。
* 以 remote_host 为 mysql_65 ， delegate_to: nginx_237 为例:
    * 当 mysql_65 的 remote_user 与 nginx_237 不同时，需要单独指定，应该设成变量，默认值即为当前 mysql_65 的 remote_user？ 这个变量如何获取？
        * 直接使用 `{{ansible_ssh_user}}` 是不行的，需要使用 set_fact 将其缓存下来
* 当在 nginx_237 执行任务后，希望触发 handler ，这个时候默认的使用 notify 的 handler 是在 mysql_65 上面执行的。
* 关于这个操作有两个选择
    1. copy_project_proxy_nginx_conf 的做成一个单独的任务，如果没有提供 project_proxy_nginx_server 变量，那么跳过任务
    2. 做成一个任务，project_proxy_nginx_server 的值默认为当前的所有主机, 暂时采用此方案, project_proxy_nginx_server: '{{ansible_play_hosts_all}}' 这是一个列表，包含了当前 playbook 的所有主机
* delegate_facts 的参数在此可以忽略
* environment: 在调用 deploy_project role 的 playbook中使用此参数时未生效，在 shell 中指定此变量时生效了。原因是此变量是在目标主机生效的
    * ANSIBLE_STDOUT_CALLBACK: skippy
 

