#!/bin/bash
export PATH={{ansible_env.PATH}}

logdir=/opt/tomcat/civp/log4j2logs
now_minute=$(date +%M)
before_hour=$(date -d '1 hour ago' +%Y-%m-%d-%H)
if [ ${now_minute} == 00 ] || [ ${now_minute} == 01 ];then
    logfile=global_api_inner.${before_hour}.log
    
else
    logfile=global_api_inner.log
fi
dt=$(date -d "2 minute ago" +%Y%m%d%H%M)

cmd="grep "${dt}" ${logdir}/${logfile}"

case $1 in
  sum_count)
    sum_count=$(${cmd} | wc -l)
    count=${sum_count}
  ;;
  failed)
    failed_count=$(${cmd} | grep '"code":"10013"' | wc -l)
    count=${failed_count}
  ;;
  succed)
    succed_count=$(${cmd} | awk -F'~#!' 'BEGIN{a=0}{if ($39=="@成功"){a++}}END{print a}')
    count=${succed_count}
  ;;
  other)
    other_count=$(${cmd} | grep -E '"code":"1000009"|"code":"50001"|"code":"1000006"' |wc -l)
    count=${other_count}
  ;;
esac

echo $count
