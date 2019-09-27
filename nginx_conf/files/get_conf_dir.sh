#!/bin/bash

#child_dirs=($(grep include nginx.conf |grep -v "share" | grep "\*\.conf" |awk '{print $NF}' |xargs dirname))
child_dirs=($(grep include nginx.conf |grep -v "share" | grep ".*\.conf" |awk '{print $NF}' |xargs dirname))
dirs_len=${#child_dirs[@]}

if [[ ${dirs_len} > 1 ]];then
    for dir in ${child_dirs[@]};do
        web_conf_dir=$(echo ${dir} |grep web)
    done
    
else
    web_conf_dir=${child_dirs[@]}
fi
if [ -n "${web_conf_dir}" ];then
    :
else
    web_conf_dir=${child_dirs[0]}
fi    
echo -n "${web_conf_dir}"
