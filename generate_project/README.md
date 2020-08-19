# description
根据 `vars/main.yml` 中的变量生成
* project 的变量文件
* project 的 Jenkinsfile
* project 的 jenkins job
* 删除指定的 job


example:

```yaml
# vars/main.yml

# 默认通用的部分可以写在这里
project_maven_options: -U clean package -Ppro -Dmaven.test.skip=true
project_src_jenkinsfile: jar-template.Jenkinsfile

project_jenkins_config: jar-template.xml
project_jenkins_url: http://jenkins.mygit.com:8080/
project_jenkins_user: admin

project_jenkins_password: 123456
project_pipeline_git_url: 'git@git.mygit.com:sa/xy_hf_ansible.git'
project_pipeline_git_credentials_id: '15865d01-62a1-45ff-9f55-d95374652f27'
project_pipeline_git_branch: '*/master'
project_pipeline_script_path: 'playbooks/user_center/files/{{project_prog_name | default(project_name, true)}}.Jenkinsfile'


projects:
  - project_name: saas-web-gateway
    project_git_url: git@git.mygit.com:saas-platform/web-gateway.git
    project_packet_name: saas-web-gateway*.jar  # 生成的包名, 可以使用通配符 如  saas-web-gateway*.jar
    project_packet_link_name: 'saas-web-gateway.jar'
    project_log_dir: /data/apps/log/saas    # 自己定义
    project_install_dir: /data/apps/opt/saas # 自己定义
    project_boot_file: common.ini   # supervisor 的一般自己提供
    project_prog_run_args: '-server -Xms4096m -Xmx4096m -jar {{project_packet_link_name}}'
    project_run_port: 9032 
    project_maven_options: -U clean package -Ppro -Dmaven.test.skip=true
    project_maven_pom_file: pom.xml # 默认是项目目录下的 pom.xml 
    project_source_dir: 'target'  #默认是项目目录下的 target 目录下找打好的 jar 包
    project_health_url:  /health # 健康检测的 url, 没有可不提供
    project_src_jenkinsfile: jar-template.Jenkinsfile
  - project_name: saas-user-portal
    project_git_url: git@git.mygit.com:saas-platform/user-portal.git
    project_npm_tool: # 自己定义， 开发提供版本
    project_install_dir: # 自己定义, 如 /data/apps/opt/saas-user-portal/ ,再加上 {{project_build_dir}} 如 build, 也就是 /data/apps/opt/saas-user-portal/build
    project_npm_args: 
    - install
    - run build
    project_run_port:
    project_boot_file:    # nginx 的配置文件，这个一般由开发提供，
    project_build_dir:    # 生成的文件的目录
    project_nginx_server_name:   # nginx 虚拟主机的名称
    project_health_url:


# playbook

- hosts: localhost
  vars_files:
  - vars/main.yml
  tasks:
  - name: generate project
    include_role:
      name: generate_project
    vars:
      project_vars: '{{project_item}}'
      project_name: '{{project_item.project_name}}'
      project_prog_name: '{{project_item.project_prog_name | default(project_item.project_name, true)}}'
      project_jenkins_name: '{{project_name}}-pipe'
    loop: '{{lookup("file", "vars/main.yml") | from_yaml | json_query("projects")}}'
    loop_control:
      loop_var: project_item


# 多子模块的变量配置示例
project_run_user: tomcat
project_dir:
  - '{{project_install_dir}}'
  - '{{project_log_dir}}'
project_packet_type: jar
project_hosts: saas_server
project_local_workdir: postloan
project_name: daihou-pl
project_maven_tool: mvn3.5_/data/apps/opt/maven
project_maven_options: clean package -Dmaven.test.skip=true
project_git_url: git@git.mygit.com:postloan/geo_pleam.git
project_src_jenkinsfile: jar-template.Jenkinsfile
project_log_dir: /data/apps/log/saas/daihou/{{project_prog_name}}
project_install_dir: /data/apps/opt/saas/daihou/{{project_prog_name}}
project_boot_file: common.ini
project_source_dir: '{{project_workspace}}/{{project_prog_name}}/target'
project_prog_jmx_args: '-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port={{project_run_port + 10000}} -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false -javaagent:/data/apps/opt/jmx_exporter/jmx_exporter.jar={{project_run_port + 20000}}:/data/apps/config/jmx_exporter/tomcat_jmx.yml'
project_packet_link_name: '{{project_prog_name}}.jar'
project_prog_run_args: '-server -Xms1g -Xmx1g {{project_prog_jmx_args}} -Deureka.client.serviceUrl.defaultZone={{project_eureka_url}} -Dserver.port={{project_run_port}} -jar {{project_packet_link_name}}'
project_health_url:  /actuator/health 




projects:
  - project_prog_name: pl-case-flashboard
    project_packet_name: '{{project_prog_name}}.jar'
    project_run_port: 9141
  - project_prog_name: pl-case-center
    project_packet_name: 'pl-strategy-center.jar'
    project_run_port: 9142
  - project_prog_name: pl-strategy-center
    project_packet_name: 'pl-strategy.jar'
    project_run_port: 9143
  - project_prog_name: pl-biz-center
    project_packet_name: '{{project_prog_name}}.jar'
    project_run_port: 9144
  - project_prog_name: pl-control-center
    project_packet_name: '{{project_prog_name}}.jar'
    project_run_port: 9145
  - project_prog_name: pl-statistics-center
    project_packet_name: '{{project_prog_name}}.jar'
    project_run_port: 9146



# 这个例子是针对一个项目下有多个子模块的
- hosts: localhost
  vars_files:
    - vars/main.yml
  tasks:
  - name: generate project
    include_role:
      name: generate_project
    vars:
      project_vars: '{{project_item}}'
      project_prog_name: '{{project_item.project_prog_name | default(project_name, true)}}' # 这一行是重点
    loop: '{{lookup("file", "vars/main.yml") | from_yaml | json_query("projects")}}'
    loop_control:
      loop_var: project_item
```


# notice
## 1. 依赖模块
这两个包是这里的task所依赖的，这个 role 不会自动安装，请自行使用yum进行安装。

如果使用的不是系统默认的 python, 比如使用了虚拟环境的话, 请使用pip进行安装。
```bash
[root@ansible ansible_roles]# yum install python2-jenkins

[root@ansible ansible_roles]# yum install python-lxml
```
