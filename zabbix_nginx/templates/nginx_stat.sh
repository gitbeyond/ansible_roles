#!/bin/bash
export PATH=/usr/lib64/qt-3.3/bin:/usr/jdk1.8.0_91/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin

cmd="cat {{zabbix_script_dir}}/nginx_status.txt"

case "$1" in
    connections)
       $cmd 2> /dev/null | awk '/connections/{print $3}'
    ;;
    accepts)
       $cmd 2> /dev/null | sed -n '3p' |awk '{print $1}'
    ;;
    handled)
       $cmd 2> /dev/null | sed -n '3p' |awk '{print $2}'
    ;;
    requests)
       $cmd 2> /dev/null  | sed -n '3p' |awk '{print $3}'
    ;;
    reading)
       $cmd 2> /dev/null  | awk '/Reading/{print $2}'
    ;;
    writing)
       $cmd 2> /dev/null  | awk '/Reading/{print $4}'
    ;;
    waiting)
       $cmd 2> /dev/null  | awk '/Reading/{print $6}'
    ;;
    *)
       echo "usage $0 {connections|accepts|hendled|requesets|reading|writing|waiting}"
       exit 2
    ;;
esac
