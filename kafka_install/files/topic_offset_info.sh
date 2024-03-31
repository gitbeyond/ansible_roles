#!/bin/bash
# editor: haifengsss163.com
# desc: getting topif offste info
kafka_base_dir=/opt/kafka
kafka_server=192.168.1.1:9092
topic_name="tomcat"

export PATH=${kafka_base_dir}/bin:$PATH

get_topic_offset_info(){
    kafka-run-class.sh kafka.tools.GetOffsetShell --broker-list ${kafka_server} --topic ${topic_name} --time -1
}

# 从 kafka 的topic中导出消息的函数，需要先使用 get_topic_offset_info 得到topic的offset信息
export_topic_message(){
    #local topic_info_file=/tmp/topic_info.txt
    local topic_info_file=$1
    local message_count=50000
    cat ${topic_info_file} | while IFS=':' read name partition offset ; do
        old_offset=$((offset-message_count))
        kafka-console-consumer.sh --bootstrap-server ${kafka_server} --topic ${name} --offset ${old_offset} --partition ${partition} --max-messages ${message_count}  > /tmp/${name}_${partition}_${message_count}.txt
    done
}
