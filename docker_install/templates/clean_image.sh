#!/bin/bash
# create date: 2022/11/29
# desc: 删除20天前的构建的本地镜像
# author: haifengsss@163.com
set -euo pipefail
# TODO: 添加删除 tag 为 <none>的image

old_day=20
lock_file=/tmp/.delete_old_img.lock
check_lock(){
    exec 3<> ${lock_file}
    if flock -n 3;then
        #echo "get ${lock_file} lock file."
        :
    else
        echo "get lock file failed. now exit."
        exit 5
    fi
}

delete_old_images(){
    dt=$(date -d "-${old_day} day" +'%Y%m%d')
    # 重点关注这里，这里是匹配旧镜像的地方
    dt_images=$(echo "${all_images}" | awk '$2~/'${dt}'$/{print $1":"$2}' )
    #echo "${dt_images}"
    if [ -n "${dt_images}" ];then
        for img in ${dt_images};do
            echo "docker rmi ${img}"
            docker rmi ${img}
        done
    fi
}
main(){
    check_lock
    all_images="$(docker images)"
    if [ -n "${all_images}" ];then
        :
    else
        echo "getting docker images is failed."
        exit 1
    fi
    # 删除20-25天前的旧镜像
    for i in {1..5};do
        delete_old_images
        old_day=$((old_day+1))
    done
}
main
