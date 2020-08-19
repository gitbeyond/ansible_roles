#!/bin/bash
export PATH=/data/apps/opt/docker:{{ansible_env.PATH}}
set -e

jenkins_home={{jenkins_home_dir}}
project_name={{project_name}}
#project_src_dir=${jenkins_home}/workspace/${project_name}/guide-admin/target
project_src_dir={{project_source_dir}}
project_packet_name={{PACKET_NAME.stdout}}

project_src_packet=${project_src_dir}/${project_packet_name}
project_work_dir={{project_k8s_work_dir}}
# 镜像的 tag 会用到这个变量
registry_addr={{docker_registry_addr}}


{%raw%}
dt=$(date +%Y%m%d)
# 镜像的标识名称
image_base_name=$1
action=$2
# 获取最新的镜像，排序方法是时间信息如 20200804
last_image=$(docker images |grep ${registry_addr} |grep ${image_base_name} | sort -n -t 2 -r |head -n 1)

# 如果没有提供 image_base_name 则退出
if [ $# -lt 1 ];then
    #echo "please input image_name and deploy_name"
    echo "please input image_name"
    exit 5
fi

# 除了可以构建镜像，还可以获取最新镜像的 tag 信息,打印信息后就退出了
if [ "${action}" == "get" ];then
    echo ${last_image} |awk '{print $1":"$2}'
    exit 0
fi 

# 检测 Dockerfile 是否存在
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

# 有时候，第一次构建镜像，并没有获得最新的镜像名，这里会定义一个
# 只是确定镜像的名称，而不包含镜像的 version 信息
# 这里需要修改，因为这里定义的总是在 geo 项目下
if [ -n "${last_image}" ];then
    image_name=$(echo ${last_image} | awk '{print $1}')
else
    image_name=${registry_addr}/geo/${image_base_name} 
fi

# 镜像的版本信息
last_image_version=$(echo ${last_image} | awk '{print $2}')
# 版本中的日期信息
last_image_date=${last_image_version:1:8}

if [ "${last_image_date}" == ${dt} ];then
    last_image_version_count=${last_image_version:9}
    last_image_version_count=${last_image_version_count:-0}
    new_image_version_count=$((10#${last_image_version_count}+1))
    # 如果最后的次数号码小于 10 就补0
    if [ ${#new_image_version_count} == 1 ];then
        new_image_version_count=0${new_image_version_count}
    fi
    new_image_version=v${dt}${new_image_version_count}
else
    new_image_version=v${dt}01
fi
#echo ${new_image_version}

#echo ${last_image_version}
# 确定了新镜像的 tag
new_image_tag=${image_name}:${new_image_version}
#echo ${new_image_tag}

# 构建镜像
docker build -t ${new_image_tag} . >&2
# push 镜像到 registry
docker push ${new_image_tag} >&2
if [ $? == 0 ];then
    echo "${new_image_tag}"
else
    exit $?
fi
{%endraw%}
