#!/bin/bash
export PATH=/usr/lib64/qt-3.3/bin:/usr/jdk1.8.0_91/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/root/bin

ip_addr=$1
# min, avg, max
mode=$2
pack_num=$3
pack_num=${pack_num:-15}
pack_interval=$4
pack_interval=${pack_interval:-1}
pack_size=$5
pack_size=${pack_size:-96}
timeout=$6
timeout=${timeout:-2}


if [ -n "${mode}" ];then
    /usr/sbin/fping -C${pack_num} -s -p${pack_interval} -b${pack_size} -t${timeout} ${ip_addr} 2>&1 1>&2 | grep "(${mode}" |awk '{print $1}'
else
    recode_str=$(echo ${ip_addr} |awk -F'.' '{print $1}')
    if a=$(/usr/sbin/fping -C${pack_num} -p${pack_interval} -b${pack_size} -t${timeout} ${ip_addr} 2> /dev/null);then
        echo ${a} | awk -vrs=${recode_str} -vpk_num=${pack_num} 'BEGIN{RS=rs;sum=0}/loss/{pos=index($10,"%"); sum+=substr($10,0,pos-1)}END{print sum/pk_num}'
    else
        echo 100
    fi
fi
