#!/bin/bash

source /etc/profile
export LC_CTYPE="en_US.UTF-8"
#export JAVA_HOME=/data/apps/opt/jdk
prog_name=$1
catalina_base=$2
action=$4
user=$3
#catalina_base=/opt/yanzhen/apache-tomcat-8.0.33
#catalina_base=/opt/tomcat/service
#service_pid=$(pgrep ${prog_name})
set -m

getpid(){
    ps aux |grep ${prog_name} |grep ${user} |grep -v -E "grep|$0" |awk '{print $2}'
}

service_pid=$(getpid ${prog_name})

status(){
    #service_pid=$(pgrep ${prog_name})
    service_pid=$(getpid ${prog_name})
    if [ -n "${service_pid}" ];then
        echo "the ${prog_name} is running, pid is ${service_pid}."
        return 0
    else
        echo "the ${prog_name} is stopped."
        return 5
    fi
}
#set -m
stop(){
    status
    if [ -n "${service_pid}" ];then
        echo "kill ${service_pid}"
        kill ${service_pid}
        echo "sleep 15"
        sleep 15
    fi
   # service_pid=$(pgrep ${prog_name})
    service_pid=$(getpid ${prog_name})
    if [ -n "${service_pid}" ];then
        echo "kill -9 ${service_pid}"
        kill -9 ${service_pid}
        echo "sleep 5"
        sleep 5
    else
        echo "${prog_name} stopped."
    fi
}


start(){
    status
    if [ $? == 5 ];then
        echo "${catalina_base}/bin/catalina.sh start"
        sudo -u ${user} -E --preserve-env=JAVA_HOME nohup ${catalina_base}/bin/catalina.sh start &> /tmp/${prog_name}.out &
        #nohup ${catalina_base}/bin/catalina.sh start &> /tmp/${prog_name}.out
    fi
}

case ${action} in 
    start)
       start
    ;;
    stop)
       stop
    ;;
    status)
       status
    ;;
    restart)
       stop
       start
    ;;
esac
