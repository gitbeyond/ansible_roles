#!/bin/bash
# date: 20200902
# author: wanghaifeng@geotmt.com
# 伪装 curl 及 wget 命令
export PATH={{ansible_env.PATH}}
recycle_bin=/tmp/.recycle_bin
real_cmd={{system_dangerous_cmd_dir}}/.{{item.dest | hash('md5')}}
self_md5=$(basename ${real_cmd})
output_file=${recycle_bin}/.virus_${self_md5}_call.out

exec 3>>${output_file}

#inhibitory_
    # 去掉 http:// 或 https:// 这种前缀
    # 去掉 url 的路径及参数
#protect_condition="
{%raw%}
protect_replacement_cmd="echo"
protect_replacement_args="https://www.baidu.com"
real_cmd_basename=$(basename ${real_cmd})
self_basename=$(basename ${0})

check_real_cmd_before_operation(){
    # 运行前检查
    # 环境变量
    # 参数等等
    # 判断是否自调用
    if [ $0 == ${real_cmd} ];then
        echo 'exit'
        exit
    fi
    if file ${real_cmd} | grep "shell script" &> /dev/null;then
        echo 'exit'
        exit 20
    fi
    # 判断real_cmd 是否存在 ，是否是一个链接文件
    # 之前发现 32.115 上的文件被换成了指向 ls 的链接文件
    if [[ -e "${real_cmd}" && ! -L "${real_cmd}" ]];then
        #${real_cmd} ${*}
        #cmd_result=$(${real_cmd} ${*})
        :
    else
        echo "${dt} ${real_cmd} is error!" >&3
        echo 'exit'
        exit
    fi
    if ${real_cmd} --help | sed -e "s@${real_cmd}@${0}@" -e "s@${real_cmd_basename}@${self_basename}@" \
        | grep ${self_basename} &> /dev/null;then
        :
    else
        echo 'exit'
        exit 21
    fi
}
check_real_cmd(){
    check_real_cmd_before_operation
}


check_real_cmd_after_operation(){
    # 运行后检查
    # 对结果进行检查
    :

}

check_real_cmd_front_pipe(){
    # 检查是否在管道前
    # 检查父命令
    :
}

check_real_cmd_behind_pipe(){
    # 检查是否在管道后
    # 检查子命令
    :
}

protect_cmd_check(){
    check_real_cmd
    for cmd_arg in ${*};do
        if [ ${cmd_arg} == "--help" ];then
            ${real_cmd} --help |\
                sed -e "s@${real_cmd}@${0}@" -e "s@${real_cmd_basename}@${self_basename}@"
            exit 0
        fi
    done
    # 返回0表示检测成功，即符合异常，那么会被替换成默认的命令执行，
    # 或者是其它定义好的命令,比如发送邮件通知等等
    for cmd_arg in ${*};do
        #echo ${cmd_arg}
        local arg_host_without_proto=${cmd_arg#*//}
        local arg_host=${arg_host_without_proto%%/*}
        local arg_file=${cmd_arg##*/}
        if [ ${#arg_host} -gt 50 ];then
            return 0
        fi
        if [[ "${arg_file}" =~ ".sh" ]];then
            return 0
        fi
        if [[ ${cmd_arg} =~ "-m" ]];then
            #local m_value=${cmd_arg:2}
            local m_value=$(echo ${cmd_arg} | grep -o '[0-9]\{1,\}')
            if [ ${m_value} -gt 50 ];then
                return 0
            fi 
        fi
        
    done
    return 1
}
#"

#${protect_condition}
protect_cmd_exec(){
    # 执行替换的命令
    # 判断替换命令是否定义
    if [ -n "${protect_replacement_cmd}" ];then
        # 判断替换参数是否定义
        # 都定义了就执行命令加参数，否则执行命令加命令行中的参数
        if [ -n "${protect_replacement_args}" ];then
            ${protect_replacement_cmd} ${protect_replacement_args}
        else
            ${protect_replacement_cmd} ${*}
        fi
    else
        # 如果没有定义替换命令，那么使用真实的命令执行相关参数
        if [ -n "${protect_replacement_args}" ];then
            ${real_cmd} ${protect_replacement_args}
        else
            echo '${real_cmd} ${*}'
        fi
    fi
}

kill_parent_prog(){
    ps -ef |grep -v grep |grep $PPID 
    kill -9 $PPID
}

if protect_cmd_check ${*};then
    protect_cmd_exec
    kill_parent_prog >&3 2>&3
else
    ${real_cmd} ${*} |& sed -e "s@${real_cmd}@${0}@" -e "s@${real_cmd_basename}@${self_basename}@"
fi
{%endraw%}
