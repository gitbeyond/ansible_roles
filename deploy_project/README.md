
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



# 目录的发布,注意，这个project_install_dir 不包含源目录的base目录，如想连同源目录一同copy,要在 project_install_dir 中写上源目录
# 如 
# src: /path/to/src 是源目录，其中包含index.html
# dest: /path/to/dest
# 最后的效果是 /path/to/dest/index.html
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
