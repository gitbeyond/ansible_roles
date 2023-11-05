
# 作用
role 的作用是安装 logstash ,并复制指定的配置文件和进程启动文件，启动进程。

# 使用
* logstash 的安装包的路径, 必须是 tar.gz 的包
    * `wget https://artifacts.elastic.co/downloads/logstash/logstash-8.10.2-linux-x86_64.tar.gz`
* 配置变量，变量见 `defaults/main.yml`
* 编写 logstash 的配置文件
* 运行 playbook, 如
```bash
- name: install logstash
  hosts: 172.16.1.1
  remote_user: root
  roles:
    - { role: logstash_install}
```

# 注意
* `logstash_is_multiple_pipeline` :如果这个变量为 true, 那么代表你的 logstash 使用的是 multiple Pipeline, 只有一个启动文件,不需要指定 `logstash_pipeline_instances` 变量,反之则代表 logstash 使用的是单 pipeline 的，那么一台机器可能会为多个 pipeline 启动多个 logstash 进程，那么需要配置 `logstash_pipeline_instances`
* `logstash_pipeline_instances`: 列表，每一项是一个字典，含义见字面意思

