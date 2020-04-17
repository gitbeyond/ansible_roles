#!/bin/bash
export PATH={{ansible_env.PATH}}
set -e

jenkins_home={{jenkins_home_dir}}
project_name={{project_name}}
#project_src_dir=${jenkins_home}/workspace/${project_name}/guide-admin/target
project_src_dir={{project_source_dir}}
project_packet_name={{PACKET_NAME.stdout}}

project_src_packet=${project_src_dir}/${project_packet_name}
project_work_dir={{project_install_dir}}
registry_addr={{docker_registry_addr}}


{%raw%}
dt=$(date +%Y%m%d)
image_base_name=$1
action=$2
last_image=$(docker images |grep ${registry_addr} |grep ${image_base_name} | sort -n -t 2 -r |head -n 1)

if [ $# -lt 1 ];then
    #echo "please input image_name and deploy_name"
    echo "please input image_name"
    exit 5
fi

if [ "${action}" == "get" ];then
    echo ${last_image} |awk '{print $1":"$2}'
    exit 0
fi 

cd ${project_work_dir}
if [ -e Dockerfile ];then
    :
else
    echo "the Dockerfile isn't exist."
    exit 6
fi

#/bin/cp ${project_src_packet} ${project_work_dir}
#/bin/cp ${project_packet_packet} ${project_work_dir}

#deploy=$2


#registry_addr=172.16.27.4:5000

if [ -n "${last_image}" ];then
    image_name=$(echo ${last_image} | awk '{print $1}')
else
    image_name=${registry_addr}/geo/${image_base_name} 
fi

last_image_version=$(echo ${last_image} | awk '{print $2}')
last_image_data=${last_image_version:1:8}

if [ "${last_image_data}" == ${dt} ];then
    last_image_version_count=${last_image_version:9}
    last_image_version_count=${last_image_version_count:-0}
    new_image_version_count=$((10#${last_image_version_count}+1))
    if [ ${#new_image_version_count} == 1 ];then
        new_image_version_count=0${new_image_version_count}
    fi
    new_image_version=v${dt}${new_image_version_count}
else
    new_image_version=v${dt}01
fi
#echo ${new_image_version}

#echo ${last_image_version}
new_image_tag=${image_name}:${new_image_version}
#echo ${new_image_tag}

docker build -t ${new_image_tag} . >&2
docker push ${new_image_tag} >&2
if [ $? == 0 ];then
    echo "${new_image_tag}"
else
    exit $?
fi
{%endraw%}
