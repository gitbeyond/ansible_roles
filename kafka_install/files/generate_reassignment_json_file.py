#-*- coding: utf-8 -*-
# editor: haifengsss@163.com
# create date: 2024/03/13
# desc: 生成 kafka 的更改 topic 副本数的 json 文件的脚本
# kafka-reassign-partitions.sh --zookeeper zk1:2181 --bootstrap-server kafka1:9092  --reassignment-json-file  topic_partition.json --execute
# 
# 使用说明：
# 1. 生成 topics.txt, 第一列是 topic 名称，第二列是 topic partition 数量
#       * 这个可以使用命令来生成: kafka-topics.sh --bootstrap-server kafka1:9092 --describe | awk '/^Topic:/{split($1, topic, ":"); split($2, part, ":"); print topic[2],part[2]}'
# 2. 更改脚本的 broker id tuple 变量
import json

topics_file='topics.txt'
brokers = (0, 1, 2,)

# 
topic_dict={
    "version": 1,
    "partitions": []
}

def get_topics_data():
    topic_data_txt=""
    with open(topics_file, 'r') as topic_data:
        topic_data_txt=topic_data.read()
    topic_data_list = topic_data_txt.split('\n')
    #print(topic_data_list)
    topic_data_dict = {}
    for i in topic_data_list:
         if len(i) == 0:
             continue
         topic_info = i.split()
         topic_data_dict[topic_info[0]] = topic_info[1]
    #
    return topic_data_dict
    
def gen_eassignment_json():
    topics_data = get_topics_data()
    tmp_t_dict= {}
    for topic_name in topics_data:
        partition_num_txt = topics_data[topic_name]
        partition_num = int(partition_num_txt)
        for i in range(partition_num):
            tmp_t_dict={
                "topic": topic_name,
                "partition": i,
                "replicas": brokers
            }
            topic_dict['partitions'].append(tmp_t_dict)
 
if __name__ == '__main__':
    gen_eassignment_json()
    print(json.dumps(topic_dict))

