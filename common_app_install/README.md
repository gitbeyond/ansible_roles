# desc

这里其实没有必要使用`import_role`的操作，单纯就是为了体验这个特性。

这是一个用来部署“通用应用”的`role`。
这些“通用应用”需要具有如下条件：
* 包类型
    * `tgz`:`tar.gz`格式，目录名最好带有版本号，方便更新操作。
    * `jar`: 比如`jmx_exporter.jar`
    * `binary`: 比如`redis_expoter`这个二进制文件，连目录都没有的
* 有配置文件，配置文件是个列表，没有也没关系
* 可以使用`supervisor`或`systemd`来进行管理


思想是定义出一些通用的操作。

针对个别有特殊需求的，单独为其再进行定义一个针对性的task。这样就大大减少了代码量。

## 不足之处
这种用法有局限性，如果一台主机上同时有 kafka, zookeeper, 使用这个role安装的话，就得将变量写在playbook当中

如果各主机配置上有些差异，就没法做区分了，因为变量名是相同的。

变量名不同时，可以在各主机或各组内定义变量，来达到差异化配置的目的。

* `https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html#id13`: ansible 变量优先级说明

对此，有如下方案。

### 方案一
1. 在`vars`目录下，分别为各`app`定义各自的变量文件;
2. 运行时，使用`include_vars`加载各自的变量，实现相应的需求。
3. 即使是这种方案，也需要至少一个变量定义在入口处
    * app_base_name: 这个是用来选择加载变量和特殊任务的入口。没有这个，仍然是不行的。

### 方案二
 
比如对于`kibana`, 定义一个 `kibana_install` 的`role`,引用当前的`role`, 在`kibana_install`中将这些变量覆盖，好像软链一样。

### 方案三

在default中定义各app开头的命名的变量(如`kibana_app_name`)，再将其转换成app_开头的变量，从而使task正常运行。

当前采用这种方案。

# examples

## kibana

```yaml
# group_vars
kibana_packet: '{{packet_base_dir}}/elasticsearch/kibana-7.15.2-linux-x86_64.tar.gz'
kibana_conf_files:
  - "kibana/node.options"
  - "kibana/kibana.yml"

kibana_run_user: kibana
kibana_boot_type: systemd
kibana_src_boot_file: 'kibana/kibana.{{app_boot_type}}'
# 想让app在配置文件发生更改时，就定义如下变量，此类变量一共有4个
kibana_conf_file_handler: app_systemd_restarted

# playbook
- hosts: sw_es_kibana
  roles:
    - role: common_app_install
      app_type_name: kibana 
```
## jmx_exporter
```yaml
# group_vars
jmx_exporter_packet: '{{packet_base_dir}}/jmx_exporter/jmx_prometheus_javaagent-0.16.1.jar'
jmx_exporter_conf_files:
  - jmx_exporter/tomcat_jmx.yml
jmx_exporter_run_user: biyao


# playbook
- hosts: tomcat
  roles:
    - role: common_app_install
      app_type_name: jmx_exporter
```

## sw_agent skywalking-java-agent

```yaml
# group_vars
sw_agent_packet: '{{packet_base_dir}}/skywalking/skywalking-agent-8.8.0.tgz'
sw_agent_run_user: biyao
sw_agent_conf_files:
  - sw_agent/agent.config
sw_agent_base_name: sw-agent


# playbook
- hosts: tomcat
  roles:
    - role: common_app_install
      app_type_name: sw_agent
```

## metricbeat
```yaml
# group_vars
metricbeat_packet: '{{packet_base_dir}}/elasticsearch/metricbeat-7.15.2-linux-x86_64.tar.gz'
metricbeat_conf_files:
  - metricbeat/metricbeat.yml
metricbeat_child_confs:
  - metricbeat/elasticsearch-xpack.yml
metricbeat_conf_file_handler:
  - app_systemd_restarted


# playbook
- hosts: sw_es
  roles:
    - role: common_app_install
      app_type_name: metricbeat
```
* https://www.elastic.co/guide/en/beats/devguide/current/creating-metricbeat-module.html : 自定义一个metricbeat的module


## node_exporter
使用这个时，遇到了`group_vars`中的变量，覆盖了默认`app_base_dir`导致的错误。

`role`中的`app_base_dir`,指的是应用的基本目录, 在`role`中，此变量为`all_app_base_dir`。
```yml

- hosts: 192.168.1.2
  #remote_user: root
  roles:
    - role: common_app_install
      vars:
        app_type_name: node_exporter
        node_exporter_packet: /data/apps/soft/ansible/prometheus/node_exporter-1.3.1.linux-amd64.tar.gz
```

# 注意

## 多个role时的变量写法

错误的示例，这种情况下，变量`app_type_name`的值总是`sw_agent`。
```yaml
- hosts: 10.9.98.201
  roles:
    - role: common_app_install
      vars:
        app_type_name: jmx_exporter
      tags:
        - install_jmx_exporter
    - role: common_app_install
      vars:
        app_type_name: sw_agent
      tags:
        - install_sw_agent
```

正确的写法:
```yaml
- hosts: 10.9.98.201
  roles:
    - role: common_app_install
      app_type_name: jmx_exporter
      tags:
        - install_jmx_exporter
    - role: common_app_install
      app_type_name: sw_agent
      tags:
        - install_sw_agent
```

## special_tasks 的执行时机问题

在部署`metricbeat`的时候，需要在复制配置文件之前，把安装目录下的modules.d复制到conf目录下。

但是这个任务在配置文件复制之后才引入，所以就出问题了。

