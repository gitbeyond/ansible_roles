#!/bin/bash
# date: 2024/11/07
# from: github.com/gitbeyond
# editor: haifengsss@163.com
set -euo pipefail

local_repo=harbor.mydomain.com/kubernetes/kubesphere
images=(
    quay.io/prometheus-operator/prometheus-config-reloader:v0.53.1
)


pull_image_base(){
    local version=${1} image_name="$2"
    docker pull ${image_name}
    # version=1 时，只保留基本名称
    local image_base_name="" local_image_name=""
    image_base_name=${image_name##*/}
    local_image_name=${local_repo}/${image_base_name}
    if [ ${version} != "1" ];then
        # getting the domain name
        local image_name_arr=(${image_name//\// })
        local image_name_arr_len=${#image_name_arr[@]}
        if [ ${image_name_arr_len} -gt 1 ];then
            # 如果第一个部分是域名，那么获得后面的除域名的部分
            local image_domain_name=${image_name_arr[0]}
            if [[ ${image_domain_name} =~ \. ]];then
                local image_name_without_domain=${image_name#*/}
                local_image_name=${local_repo}/${image_name_without_domain}
            else
                # 
                local_image_name=${local_repo}/${image_name}
            fi
        else
            local_image_name=${local_repo}/${image_name}
        fi
    fi

    docker tag ${image_name} ${local_image_name}
    docker push ${local_image_name}
    #docker rmi ${local_image_name}
    #docker rmi ${image_name}
}

# 最后统一删除，有时候各个镜像会有共同依赖的层，每次都删除会浪费时间
delete_old_images(){
    #local image_name="${1}"
    local all_images="" image_info=() image_digest=""
    local image_only_name="" image_only_tag=""
    all_images=$(docker images)
    # 遍历要拉取的镜像列表
    for image_name in ${images[@]};do
        image_only_name="${image_name%:*}"
        image_only_tag="${image_name#*:}"
        # 获取镜像的摘要
        image_digest=$(awk -v image_only_name="${image_only_name}" -v image_only_tag=${image_only_tag} '$1 == image_only_name && $2 == image_only_tag {print $3; exit}' <<<"${all_images}")
        if [ -n "${image_digest}" ];then
            # 根据摘要获取所有的 tag 
            image_info=($(awk -v image_digest="${image_digest}" '$3 == image_digest {print $1":"$2}' <<<"${all_images}"))
            for new_image in ${image_info[@]};do
                docker rmi ${new_image}
            done
        fi
    done
}

# 这个是忽略镜像的路径信息，比如 quay.io/prometheus/node-exporter:v1.3.1 ，只会保留后面的 node-exporter:v1.3.1
pull_image_to_local_v1(){
    local image_name="$1"
    pull_image_base 1 ${image_name}
}

pull_image_to_local_v2(){
    local image_name="$1"
    pull_image_base 2 ${image_name}
}

main(){
    for i in ${images[@]};do
        pull_image_to_local_v2 ${i}
    done
    delete_old_images 
}

main
