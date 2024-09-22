#!/bin/bash
# editor: haifengsss@163.com
# desc:
# 接受一个网卡名称，如 lxc5a3a70307275, 注意，不要带@以及后面的内容
# 输出，此网卡对应的容器信息 
# bash /tmp/find_container_by_veth.sh lxc5a3a70307275
# 0b75bc175fd3 0 53fdfe27fce8d9992a53c138994491e1e4b27e32ae91c2700eb027ca65f9e9e8 ingress-nginx-1

set -euo pipefail

docker_netns_dir=/var/run/docker/netns
ip_netns_dir=/var/run/netns

get_all_containers_id(){
    #docker ps  |grep -v "/pause" | tail -n +2 |awk '{print $1}'
    #docker ps | awk '$3!="\"/pause\"" && $1!="CONTAINER"{print $1}'
    # 由于 sandbox Key 只存在于 pause 容器中，所以需要获取全量容器 Config.Hostname 可以得到业务容器的名称
    docker ps | awk '$1!="CONTAINER"{print $1}'
    # docker 19.03.9 don't work
    #docker ps --format '{{if ne .Command "\"/pause\"" }}{{print .ID}}{{else}}{{end}}'
    #docker ps --format '{{if (.Image) and ne .Image "ccr.ccs.tencentyun.com/library/pause:latest" }}{{.ID}}{{else}}{{end}}'
}

test_container_sandbox_key(){
    local container_id=$1 sandbox_key=$2
    #docker inspect ${container_id} --format '{{ .State.Pid }} {{.NetworkSettings.SandboxKey}}'
    docker inspect ${container_id} --format '{{ if eq .NetworkSettings.SandboxKey '\"${sandbox_key}\"' }}{{.ID}} {{.Config.Hostname}}{{end}}'
}

# 通过网卡名称获取其对端的 nsid
get_veth_link_nsid(){
    local veth_name=$1
    ip li sh "${veth_name}" | awk '/link\/ether/{print $NF}'
}

# 通过 nsid 得到 sandbox key
get_sandbox_key_by_nsid(){
    local nsid=$1
    ip netns list | awk '/id: '${nsid}'/{print $1}'
}
link_ns_id(){
    #
    [ -d ${ip_netns_dir} ] || mkdir -p ${ip_netns_dir}
    if [ -d ${docker_netns_dir} ];then
        :
    else
        echo "The ${docker_netns_dir} isn't exist."
        return 10
    fi
    #set +f
    #eval "ln -sv ${docker_netns_dir}/* ${ip_netns_dir}/" || /bin/true
    local all_container_ns=$(ls -1 ${docker_netns_dir})
    for nf in ${all_container_ns};do
        if [ -h ${ip_netns_dir}/${nf} ];then
            :
        else
            ln -sv ${docker_netns_dir}/${nf} ${ip_netns_dir}
        fi
    done
    # delete absent file
    local all_netns_file
    all_netns_file=$(ls -go ${ip_netns_dir} | awk '/^l/{print $(NF-2), $NF}')
    #echo "${all_netns_file}"
    [ -n "${all_netns_file}" ] || return 0
    echo "${all_netns_file}" | while read ns_name ns_link;do
        #echo "ns_name: ${ns_name}, ns_link: ${ns_link}"
        if [ -e ${ns_link} ];then
            :
        else
            echo "/bin/rm ${ip_netns_dir}/${ns_name}"
            /bin/rm ${ip_netns_dir}/${ns_name}
        fi
    done
}

main(){
    link_ns_id
    # 根据网卡获取对端的 ns id
    nsid=$(get_veth_link_nsid ${1})
    sandbox_key=$(get_sandbox_key_by_nsid ${nsid})
    #
    sandbox_key_full_path=${docker_netns_dir}/${sandbox_key}
    all_container_ids=$(get_all_containers_id)
    # 遍历 container id，检查其 netns 路径
    for c_id in ${all_container_ids};do
        test_ret=$(test_container_sandbox_key ${c_id} ${sandbox_key_full_path})
        if [ -n "${test_ret}" ];then
            echo ${sandbox_key} ${nsid} ${test_ret}
            break
        fi
    done
}
main "${@}"

