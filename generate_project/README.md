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
project_jenkins_url: http://jenkins.ops.geotmt.com:8080/
project_jenkins_user: admin

project_jenkins_password: geotmt@000
project_pipeline_git_url: 'git@git.geotmt.com:sa/xy_hf_ansible.git'
project_pipeline_git_credentials_id: '15865d01-62a1-45ff-9f55-d95374652f27'
project_pipeline_git_branch: '*/master'
project_pipeline_script_path: 'playbooks/user_center/files/{{project_prog_name | default(project_name, true)}}.Jenkinsfile'


projects:
  - project_name: saas-web-gateway
    project_git_url: git@git.geotmt.com:saas-platform/web-gateway.git
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
    project_git_url: git@git.geotmt.com:saas-platform/user-portal.git
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
      project_vars: '{{item}}'
      project_name: '{{item.project_name}}'
      project_jenkins_name: '{{project_name}}-pipe'
    loop: '{{lookup("file", "vars/main.yml") | from_yaml | json_query("projects")}}'
```
