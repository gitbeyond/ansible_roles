
# role 的作用 
部署`kafka`集群。

## download zk

```bash
wget https://archive.apache.org/dist/kafka/2.2.0/kafka_2.12-2.2.0.tgz
```

## 这个 role 的作用是安装一个 kafka 集群.
* 创建用户
* 创建目录
* 安装 kafka 的 tar.gz 包
* 复制配置文件
    * 这里还会生成一个环境变量文件，使用方法见例子
* 启动 zookeeper, supervisor 或者 systemd


## 示例

变量
```yaml
# kafka_id 需要在各个hosts上设定
kafka_zk_url: '192.168.10.100:2181,192.168.10.101:2181,192.168.10.102:2181'
# 指定自己的配置文件
kafka_conf_files:
  - server.properties
```

```yaml
- hosts: qa_thanos_query
  roles:
  - role: kafka_install
    kafka_boot_type: systemd
    kafka_packet: /data/apps/soft/ansible/kafka/kafka_2.12-2.2.0.tgz
    kafka_install_dir: /opt/server
    kafka_base_dir: /opt/server/kafka
    kafka_log_dir: /var/log/kafka
    kafka_data_dir: /var/data/kafka
    kafka_conf_dir: '{{kafka_base_dir}}/config'
    kafka_env_vars:
      - name: JAVA_HOME
        value: '{{ansible_env.JAVA_HOME}}'
      - name: PATH
        value: '{{ansible_env.PATH}}'
      - name: KAFKA_HEAP_OPTS
        value: '-Xmx2G -Xms2G'
      - name: LOG_DIR
        value: '{{kafka_log_dir}}'
        # 这个是为了在调用kafka的脚本，如kafka-topic.sh的时候方便
      - name: kafka_broker_list
        value: '192.168.10.100:9092,192.168.10.101:9092,192.168.10.102:9092'
```



# kafka启动时的环境变量

在`2.12-2.2.0`的版本当中，`kafka-server-start.sh`中用到了如下变量:
* KAFKA_LOG4J_OPTS , 指定日志配置文件的变量
* KAFKA_HEAP_OPTS, 指定kafka堆内存配置的变量, 默认值为 `-Xmx1G -Xms1G`
* EXTRA_ARGS , 其他的变量，默认值为 `-name kafkaServer -loggc`, 传给`kafka-run-class.sh`的变量

`kafka-run-class.sh`中的变量
* KAFKA_JMX_OPTS
* LOG_DIR , 默认值: `$base_dir/logs`
* 



# kafka的高可用测试

```bash
# ../bin/kafka-topics.sh --bootstrap-server ${kafka_broker_list}  --list
test_topic1
# ../bin/kafka-topics.sh --bootstrap-server ${kafka_broker_list}  --describe --topic test_topic1
Topic:test_topic1	PartitionCount:2	ReplicationFactor:2	Configs:min.insync.replicas=1,segment.bytes=1073741824,max.message.bytes=5242880
	Topic: test_topic1	Partition: 0	Leader: 1	Replicas: 1,2	Isr: 1,2
	Topic: test_topic1	Partition: 1	Leader: 2	Replicas: 2,3	Isr: 2,3

```

生产
```bash
# ./kafka-console-producer.sh --broker-list ${kafka_broker_list} --topic test_topic1
>test
>test2
>test3
>test6
>test7
```


消费
```bash
# ./kafka-console-consumer.sh --topic test_topic1 --bootstrap-server ${kafka_broker_list}
test3
test6
ttest7
```

运行一个持续生产的脚本
```bash
# a=1; while true; do echo test${a}; a=$((a+1)); sleep 0.1; done | ./kafka-console-producer.sh --broker-list ${kafka_broker_list} --topic test_topic1
```


停止kafka 的 1节点
```bash
# systemctl status kafka
● kafka.service - Apache kafka service
   Loaded: loaded (/usr/lib/systemd/system/kafka.service; disabled; vendor preset: disabled)
   Active: active (running) since 二 2023-01-31 13:42:48 CST; 34min ago
 Main PID: 26127 (java)
   CGroup: /system.slice/kafka.service
           └─26127 /opt/java/java/bin/java -Xmx2G -Xms2G -server -XX:+UseG1GC -XX:MaxGCPauseMillis=20 -XX:InitiatingHeapOccupancyPercent=35 -XX:+ExplicitGCInvokesConcurrent -Djava....

# systemctl stop kafka
# systemctl status kafka
● kafka.service - Apache kafka service
   Loaded: loaded (/usr/lib/systemd/system/kafka.service; disabled; vendor preset: disabled)
   Active: inactive (dead)

```


topic的情况
```bash
[2023-01-31 14:17:08,483] WARN [AdminClient clientId=adminclient-1] Connection to node -1 (/192.168.10.100:9092) could not be established. Broker may not be available. (org.apache.kafka.clients.NetworkClient)
Topic:test_topic1	PartitionCount:2	ReplicationFactor:2	Configs:min.insync.replicas=1,segment.bytes=1073741824,max.message.bytes=5242880
	Topic: test_topic1	Partition: 0	Leader: 2	Replicas: 1,2	Isr: 2
	Topic: test_topic1	Partition: 1	Leader: 2	Replicas: 2,3	Isr: 2,3

```

生产者warn信息
```bash
# a=1; while true; do echo test${a}; a=$((a+1)); sleep 0.1; done | ./kafka-console-producer.sh --broker-list ${kafka_broker_list} --topic test_topic1
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>[2023-01-31 14:16:56,616] WARN [Producer clientId=console-producer] Connection to node 1 (/192.168.10.100:9092) could not be established. Broker may not be available. (org.apache.kafka.clients.NetworkClient)

```

消费者没有异常
```bash
test12718
^CProcessed a total of 12721 messages
# ./kafka-console-consumer.sh --topic test_topic1 --bootstrap-server ${kafka_broker_list}
```


启动了刚才的kafka之后, 这里的 partition-0 出现了 leader 切换的问题
```bash
# ../bin/kafka-topics.sh --bootstrap-server ${kafka_broker_list}  --describe --topic test_topic1
Topic:test_topic1	PartitionCount:2	ReplicationFactor:2	Configs:min.insync.replicas=1,segment.bytes=1073741824,max.message.bytes=5242880
	Topic: test_topic1	Partition: 0	Leader: 2	Replicas: 1,2	Isr: 2,1
	Topic: test_topic1	Partition: 1	Leader: 2	Replicas: 2,3	Isr: 2,3

```


生产者出现的报警日志
```bash
[2023-01-31 14:42:03,083] WARN [Producer clientId=console-producer] Got error produce response with correlation id 140 on topic-partition test_topic1-0, retrying (2 attempts left). Error: NOT_LEADER_FOR_PARTITION (org.apache.kafka.clients.producer.internals.Sender)
[2023-01-31 14:42:03,084] WARN [Producer clientId=console-producer] Received invalid metadata error in produce request on partition test_topic1-0 due to org.apache.kafka.common.errors.NotLeaderForPartitionException: This server is not the leader for that topic-partition.. Going to request metadata update now (org.apache.kafka.clients.producer.internals.Sender)

```
