#!/bin/bash
#. /etc/profile
#. /etc/bashrc

#src_dir=/data/apps/data/jenkins_archive_data/yx-loan-test-master-docker
project_name=${JOB_NAME:-$1}
project_packet_name="${2}"
#src_dir=/data/apps/data/jenkins_archive_data/${project_name}
src_dir=/data3/apps/data/jenkins_data/${project_name}
echo 0
if [ -e ${src_dir} ];then 
    cd ${src_dir}
else
    exit 5
fi
ls ${project_packet_name}* |grep "[0-9]$" |awk -F'_' '{print $NF}' |sort -t'-' -k1 -n

