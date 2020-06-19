
这个 role 的作用是配合 jenkins 发布项目。

使用示例
```yaml
- hosts: '{{project_host}}'
  remote_user: root
  roles:
    - { role: deploy_project, project_run_user: "tomcat",
        project_prog_name: "xxl-syncdsconf",
        project_packet_name: "syncdsconf*.jar", 
        project_packet_link_name: "fk-syncdsconf.jar",
        project_name: "xxl-job-admin", 
        project_boot_type: "supervisor",
        project_boot_file: "/data/apps/data/ansible/{{project_name}}/{{project_prog_name}}.ini",
        project_source_dir: "{{project_workspace}}/xxl-job-executor-samples/syncdsconf/target",
        project_install_dir: "/data/apps/opt/{{project_prog_name}}",
        project_log_dir: "/data/apps/log/xxl-job" }



# 目录的发布,注意，源目录带不带最后的 '/' 将产生不同的效果
# 如 
# src: /path/to/src 是源目录，其中包含index.html
# dest: /path/to
# 最后的效果是 /path/to/src/index.html
# src: /path/to/src/ 是源目录，其中包含index.html
# dest: /path/to
# 最后的效果是 /path/to/index.html
# project_packet_link_name 软链的名字要写成绝对路径的方式
- hosts: '{{project_host}}'
  remote_user: root
  roles:
    - { role: deploy_project,
        project_run_user: "nginx",
        project_prog_name: "web1",
        project_packet_name: "build", 
        project_packet_link_name: "/data/apps/opt/myweb",
        project_name: "web1", 
        project_boot_type: "nginx",
        project_boot_file: "/data/apps/data/ansible/{{project_name}}/{{project_prog_name}}.conf",
        project_source_dir: "{{project_workspace}}",
        project_install_dir: "/data/apps/opt/{{project_prog_name}}",
        project_log_dir: "/data/apps/log/nginx" }
```

变量说明
* `project_prog_name`: 如果是一个后台进程使用 supervisor 或者 systemd 管理时的服务名称
* `project_packet_name`: 打包好的包名称，因为有的包名的版本号会变动，所以此处使用了通配符`syncdsconf*.jar`
* `project_packet_link_name`: 一个指向真正包的链接文件，这样的话，当原始包名发生变动时，只要更改软链即可，不用修改 supervisor 的配置文件
* `project_boot_type`: 有 supervisor 和 nginx, systemd 三个选项，
    * nginx 的是指一些前端项目，这个项目发布时会连同配置文件一起发布，所以会 reload nginx
    * supervisor 与 systemd 都是会启动进程的，这个酌情选择即可，都需要连同其服务配置文件一起写上
    * k8s 这个类型的会用 template 生成 k8s 的资源文件，而后向集群进行提交，这个支持有限，有些资源提交时会报错
    * docker 这个只会生成镜像
* `project_boot_file`: 包的服务配置文件，如果是前端项目，这个role会将 nginx 子配 `{{nginx_conf_dir}}/conf.d` 下


# 注意
* 当使用 `include_tasks` 时，不能在执行 playbook 时指定 --tags ，这种情况下指定的 tags 如果是由 `include_tasks` 所包含的，那么什么都不会执行
* `include_tasks` 的时候，可以指定一个 name, 当不指定 --tags 时，在包含成功还是skipping的时候，会显示这个 name, import_tasks 的则不会，跳过时会依次跳过所包含的yml中的所有任务
* `include_tasks` 的任务可以使用 loop 关键字，而 `import_tasks` 的则不能
