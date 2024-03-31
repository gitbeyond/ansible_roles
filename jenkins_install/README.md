# desc

安装jenkins的role。

尚有待完善之处。

## plugins
* https://www.jenkins.io/zh/blog/2019/10/28/introducing-new-folder-authorization-plugin/ : 介绍新的文件夹授权插件
* https://github.com/jenkinsci/configuration-as-code-plugin/blob/master/README.md : 通过配置文件快速配置一个jenkins实例
* https://docs.cloudbees.com/docs/admin-resources/latest/cli-guide/non-trust-store-ssl : 一些关于jenkins的文档

# examples


```yaml
- hosts: dev_jenkins
  roles:
  - role: jenkins_install
    jenkins_app_name: 'dev-jenkins'
    jenkins_run_user: 'jenkins'
    jenkins_war_file: '/data/apps/soft/ansible/jenkins/2.414.3/jenkins-2.414.3.war'
    jenkins_install_dir: '/opt/server/{{jenkins_app_name}}'
    jenkins_data_dir: '/opt/data/{{jenkins_app_name}}'
    jenkins_log_dir: '/opt/log/{{jenkins_app_name}}'
    jenkins_boot_script: 'jenkins/jenkins.sh'
    jenkins_run_port: 8090
    jenkins_java_opts: '-Xms8g -Xmx8g'
    jenkins_backup_script: ''
```

# 代理时的跳转问题

访问的 https , 但是却返回了 http, 这时候需要配置`proxy_redirect`
```bash
# curl -i  -b 'JSESSIONID.2dcfe27b=node059lp3lklqebt1b25unmi5ro4q1.node0' https://my-jenkins.test.com/manage  --resolve my-jenkins.test.com:443:172.22.1.11
HTTP/1.1 302 Found
Server: nginx
Date: Fri, 20 Oct 2022 09:49:00 GMT
Transfer-Encoding: chunked
Connection: keep-alive
X-Content-Type-Options: nosniff
Location: http://my-jenkins.test.com/manage/
```

# 官方文档中的proxy配置

* https://www.jenkins.io/doc/book/system-administration/reverse-proxy-configuration-with-jenkins/reverse-proxy-configuration-nginx/ : Reverse proxy - Nginx
