# role 的作用是安装 elasticsearch 集群

操作如下:
1. 创建用户
2. 创建目录
3. 安装 elasticsearch
4. 复制配置文件
5. 修改内核参数
6. 启动 elasticsearch


example:
```yaml
# group_vars/es_76.yml
es_packet: '{{packet_base_dir}}/elasticsearch-5.6.11.tar.gz'

es_confs:
  - "jvm.options"
  - "elasticsearch.yml"

es_data_dir:
  - /data1/apps/data/elasticsearch
  - /data2/apps/data/elasticsearch
  - /data3/apps/data/elasticsearch
  - /data4/apps/data/elasticsearch

es_cluster_name: zxw_es

# playbook
- hosts: es_76
  remote_user: root
  roles:
    - { role: elasticsearch_install}
```
