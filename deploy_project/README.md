
这个 role 的作用是配合 jenkins 发布项目。

使用示例
```bash
- hosts: '{{project_host}}'
  remote_user: root
  roles:
    - { role: deploy_project, project_run_user: "tomcat",
        project_prog_name: "xxl-syncdsconf",
        project_packet_name: "syncdsconf*.jar", project_packet_link_name: "fk-syncdsconf.jar",
        project_name: "xxl-job-admin", project_boot_type: "supervisor",
        project_boot_file: "/data/apps/data/ansible/{{project_name}}/{{project_prog_name}}.ini",
        project_source_dir: "{{jenkins_home_dir}}/workspace/{{project_name}}/xxl-job-executor-samples/syncdsconf/target",
        project_install_dir: "/data/apps/opt/{{project_prog_name}}",
        project_log_dir: "/data/apps/log/xxl-job" }
```

变量说明
* project_prog_name: 如果是一个后台进程使用 supervisor 或者 systemd 管理时的服务名称
* project_packet_name: 打包好的包名称，因为有的包名的版本号会变动，所以此处使用了通配符"syncdsconf*.jar"
* project_packet_link_name: 一个指向真正包的链接文件，这样的话，当原始包名发生变动时，只要更改软链即可，不用修改 supervisor 的配置文件
* project_boot_type: 有 supervisor 和 nginx, systemd 三个选项，
    * nginx 的是指一些前端项目，这个项目发布时会连同配置文件一起发布，所以会 reload nginx
    * supervisor 与 systemd 都是会启动进程的，这个酌情选择即可，都需要连同其服务配置文件一起写上
* project_boot_file: 包的服务配置文件，如果是前端项目，这个role会将 nginx 子配 {{nginx_conf_dir}}/conf.d 下
