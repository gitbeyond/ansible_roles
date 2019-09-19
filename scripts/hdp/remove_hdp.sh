#!/bin/bash



if [ "${1}" != "delete_hadoop" ];then
    echo "please support 'delete_hadoop' args."
    exit 5
fi

hdp_install_packet=$(yum list all 2> /dev/null |grep -i -E '\@hdp|\@ambari' | awk '{print $1}')

hdp_users=(
ams
ambari-qa
hadoop
hdfs
users
hbase
hcat
hive
hcat
kafka
mapred
spark
spark
storm
tez
httpfs
yarn
zookeeper
)

hdp_dirs=(
/hadoop
/usr/hdp
/usr/lib/ambari-agent
/usr/lib/ambari-server
/usr/bin/ambari-python-wrap
/usr/lib/hadoop
/usr/lib/flume
/usr/lib/storm
/usr/lib/hadoop-yarn
/var/lib/ambari-agent
/var/lib/ambari-server
/var/lib/hadoop-hdfs
/var/lib/hive
/var/lib/hadoop-mapreduce
/var/lib/hadoop-yarn
/var/lib/zookeeper
/var/log/hadoop-hdfs
/var/log/ambari-agent
/var/log/ambari-metrics-monitor
/var/log/ambari-server
/var/log/hadoop
/var/log/hadoop-mapreduce
/var/log/hadoop-yarn
/var/log/hbase
/var/log/kafka
/var/log/ranger
/var/log/spark
/var/log/zookeeper
/var/log/hive
/var/log/storm
/var/log/webhcat
/tmp/hadoop-*
/tmp/hbase*
/tmp/hdfs
/tmp/hive
/tmp/hsperfdata_ambari-qa
/tmp/hsperfdata_hbase
/tmp/hsperfdata_hcat
/tmp/hsperfdata_hdfs
/tmp/hsperfdata_hive
/tmp/hsperfdata_kafka
/tmp/hsperfdata_yarn
/tmp/ambari-qa
/etc/ambari*
/etc/hadoop
/etc/hbase
/etc/hive
/etc/zookeeper
/etc/storm
/etc/hive-hcatalog
/etc/tez
/etc/hive-webhcat
/etc/kafka
/etc/slider
/etc/storm-slider-client
/etc/ranger
/var/run/hadoop
/var/run/hbase
/var/run/hive
/var/run/zookeeper
/var/run/storm
/var/run/webhcat
/var/run/hadoop-yarn
/var/run/hadoop-mapreduce
/var/run/kafka
)
hdp_delete_user(){
    #local users=$1
    for user in ${hdp_users[@]};do
        if groupmems -g ${user} -l &> /dev/null;then
            echo "groupdel ${user}"
            group_del_result=$(groupdel ${user})
            group_del_stat=$?
            [ $group_del_stat -ne 0 ] && echo "the ${user} group del failed. the result is ${group_del_result}"
        fi
        if id ${user} &> /dev/null;then
            echo "userdel -r ${user}"
            user_del_result=$(userdel -r ${user})
            user_del_stat=$?
            [ $user_del_stat -ne 0 ] && echo "the ${user} del failed."
        fi
        
    done
}

hdp_kill_user_process(){
    for user in ${hdp_users[@]};do
        if id ${user};then
            user_pids=$(ps -ef |grep -v grep | grep "^${user}" |awk '{print $2}')
            if [ -n "${user_pids}" ];then
                kill -9 ${user_pids}
            fi
        else
            #echo "the ${user} isn't exist. continue."
            continue
        fi
    done
}
hdp_delete_dir(){
    #local dir=${1}
    for i in ${hdp_dirs[@]};do
        if [ -e ${i} ];then
            echo "rm -rf ${i}"
            rm -rf ${i}
        fi
    done
}
echo "hdp_kill_user_process"
hdp_kill_user_process

#exit 5
if [ -n "${hdp_install_packet}" ];then 
    echo "yum -y remove ${hdp_install_packet}"
    yum -y remove ${hdp_install_packet}
fi

echo "hdp_delete_user ${hdp_users}"
hdp_delete_user ${hdp_users}


echo "hdp_delete_dir ${hdp_dirs}"
hdp_delete_dir ${hdp_dirs}

