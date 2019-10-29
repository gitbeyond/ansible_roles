#!/bin/bash

redis_pass=${3}
export REDISCLI_AUTH=${redis_pass}
redis_port=${2}
redis_host=${1}

redis_cmd=/usr/local/bin/redis-cli

#${redis_cmd} -a ${redis_pass} -p ${redis_port} -h ${redis_host} PING
ping_result=$(${redis_cmd} -p ${redis_port} -h ${redis_host} PING)
if [ "${ping_result}" == "PONG" ];then
    :
else
    exit 5
fi

role_result=$(${redis_cmd} -p ${redis_port} -h ${redis_host} INFO REPLICATION |grep -o "role:master")
role_result=${role_result}

if [ "${role_result}" == "role:master" ];then
    :
else
    exit 6
fi
