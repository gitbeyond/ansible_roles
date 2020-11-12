#!/bin/bash

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin

redis_cli=/usr/src/redis-3.0.3/src/redis-cli

hosts=(172.16.9.39 172.16.9.40 172.16.9.79 172.16.9.80)

#declare -A state
#for i in ${hosts[@]};do
#    $redis_cli -h $i -a 123456 info > /tmp/${i}_redis.info
#    stat=$?
#    state[${i}]=$stat
#done
#
##echo ${state[@]}
##echo ${!state[@]}
#echo ${state[$1]} | grep -c '0'

catch() {
    $redis_cli -h ${1} -a 123456 info > /tmp/${1}_redis.info_1 2>> /tmp/${1}_redis.error && mv /tmp/${1}_redis.info_1 /tmp/${1}_redis.info
    stat=$?
    echo $stat | grep -c '0'
}

catch ${1}
