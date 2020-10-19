

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


delegate_facts 的测试
```yaml
- name: test delegate vars1
  shell: "echo inventory_hostname: {{inventory_hostname}}, hostname: $(hostname)"
  delegate_to: '{{item}}'
  loop: '{{groups[nginx_server]}}'
  run_once: true
  remote_user: '{{nginx_server_remote_user}}'
```
上面这种未使用 delegate_facts 参数，那么 `{{inventory_hostname}}` 为 mysql_65 中的一台机器，$(hostname) 则是真实的 mongo_237 机器(任务是在这上面执行的)。

添加了 delegate_facts 参数之后，发现效果一样,暂时不解。
 
# 2020/06/17 defaults/main.yml add `project_run_port: 80`

config-repo  是一个不需要启动的项目，它的配置文件中没有 project_run_port 变量，然后在生成 project_monitor_data 变量时就报错了。因此添加一个 project_run_port: 80 的默认变量 


# 2020/06/19 use include_tasks and import_tasks rewrite main.yml

通过结合 include_tasks 和 import_takss，减少了 main.yml 中的冗余代码，使结构更加清晰，且减少了执行时的output信息。

目的是:
1. 不指定 tags 时，信息量能少一些，至少信息不能多
2. 可以选择指定 tag， 减少不必要的判断(这里目前做得并不好，后续的 url_check, archive_packet 都不能显式地跳过)

* 第一种方式: 实现 project_supervisor_jar, project_nginx_tgz, project_nginx_directory ...， 即使用 boot_type 与 packet_type 结合的方式
    * 好处是可以使用 tag 指定相关类型的tag, 实现精细化运行
    * 问题是像 project_nginx_tgz 或 project_nginx_directory 当中都引入了 boot_project_for_nginx.yml 这个文件，当不指定 tag 的时候，且条件不满足时会发生多次跳过同一个任务的情况，信息十分繁琐。

* 第二种方式: 将各个包类型的 yml 放至一个 使用 include_tasks 引入一个 yml 文件中，然后 import 这个文件，如
```yaml
- include_tasks: install_project_packet_for_{{project_packet_type}}.yml
  tags:
    - install_project_packet
```
这样的话，如果不指定 tag 时，只会显示一次 include_tasks，指定 tag 只是可以显式执行某一部分的操作了,比如，只执行 更新 启动文件的操作这样，有一些操作是有依赖性的，比如 `install_packet` 的就依赖 `get_packet_name` 的, 这个依赖性，这个依赖性后面再关注


* 包类型多种
* 启动类型多种

* 启动之后的操作
    * 是否复制 project_proxy_nginx_conf
    * 是否进行健康检测
    * 是否对包进行归档, 如果要进行归档，那么得对健康检测没问题的才归档(k8s 上的无法检测,)
        * systemd 或 supervisor 启动的二进制类型的包才进行健康检测 
    * 是否生成监控和日志数据

# 2020/07/09 增加使用 file 来完成日志与监控的操作

考虑到有些场景不可能有 ansible-confd 的存在，所以增加了
* project_filebeat_conf
* project_prom_file_sd_conf
* project_prom_conf: project_prom_file_sd_conf 变量的别名
* project_prom_file_sd_dir
来将相关的文件直接复制至相关目录来完成日志的收集，和监控的添加。

不放弃原来的方法，增加如下变量,目前的可取值为 file 和 etcd(etcd3)
* project_log_data_generate_method
* project_monitor_data_generate_method

考虑得更广泛一些的话，收集日志可能使用的不是 filebeat, 而是用 promtail, fluent-bit 等其他组件，  
那么变量名称叫做 project_filebeat_conf 就不太合适了。  

这个也适用于监控系统，比如使用的是 zabbix,或statsd  而不是 prom，其处理逻辑就不一样。

还有 nginx, 现在的变量叫做 project_nginx_confs, 而像 treafik, BFE,Envoy 等前端代理的发展，很可能就会替代 nginx。

所以再增加:
* `project_log_collect_conf: # 对应filebeat配置文件`
* `project_log_conf_dir: # 对应filebeat配置文件的目录`
* `project_monitor_conf`: # 对应project_prom_conf
* `project_monitor_conf_dir`: # 对应project_prom_file_sd_dir

# 2020/08/04 部署 bert on k8s 遇到问题，增加如下变量

* project_k8s_work_dir: '{{project_install_dir}}'
* project_source_packet_name: '{{project_source_dir}}/{{project_packet_name}}'
* project_packet_link_src_name:
* project_packet_mode:
* project_packet_set_mode

# 2020/08/10 使用 include_role: docker_image 来替代了原先的脚本构建镜像的方式

* docker_image 构建镜像可以实现幂等性,当镜像实际内容没有变化时，其 changed: false,只是添加一个 tag，可以对此进行判断来决定是不是要更新集群中 app 的image,但是有些时候我们希望的是"即使只是更新了tag,也希望其应用到集群当中",所以暂时没有做判断，而是每一次都向集群中提交。

# 2020/08/19 project_set_proxy_nginx_conf 部分的修改

这一块 delegate_to 的 host 没办法使用其上的 fact, 设置了 `delegate_facts: True` 时，反而会报错
```
An exception occurred during task execution. To see the full traceback, use -vvv. The error was: UnboundLocalError: local variable 'module_style' referenced before assignment
```
所以改为 setup 加 register 方式来实现相关的操作。

# 2020/10/19 针对 project_packet_type 及 project_boot_type 的值分别编写相关的 var 文件，后续尝试在 tasks 中 include_vars 这些文件

由于变量繁多，直接从零编写一份变量配置，总是会漏掉一些。 
现在想的是把各个类型的配置总结出来，能引用的话，最好，不能引用，照着这个模板改一下也好，省得总是出错。

目前这个工作只是做了初步，仍然有待修改。






