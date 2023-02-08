#!/bin/bash
set -euo pipefail
#  kafka vars
kafka_log_dir="{{kafka_log_dir}}"
#kafkaServer-gc.log , 这个可以配置保留多少份，所以不需要关注
# {%raw%}
kafka_logs=(
    controller.log
    kafka-authorizer.log
    kafka-request.log
    log-cleaner.log
    server.log
    state-change.log
)
kafka_log_keep_days=10
kafka_log_dt_format='%Y-%m-%d-%H'
kafka_log_dt_day_format='%Y-%m-%d'
kafka_delete_log(){
    local log_file_name="$1"
    local dt=$(date -d"-${kafka_log_keep_days} days" +"${kafka_log_dt_day_format}")
    cd ${kafka_log_dir}
    local log_files=$(ls ${log_file_name}.${dt}-{00..23})
    if [ -n "${log_files}" ];then
        echo "$(date) rm -rf ${log_files}"
        # rm -rf ${log_files}
    fi
}

main(){
    echo "$(date) start to delete kafka old logs."
    for f in ${kafka_logs[@]};do
        kafka_delete_log "${f}"
    done
    echo "$(date) the end."
}
main
# {%endraw%}
