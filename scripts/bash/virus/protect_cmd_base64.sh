#!/bin/bsah


real_cmd=base64
#inhibitory_
    # 去掉 http:// 或 https:// 这种前缀
    # 去掉 url 的路径及参数
#protect_condition="

protect_cmd_check(){
    #echo "all args: ${@}"
    #echo "all args: ${*}"
    cmd_result=$(${real_cmd} ${*})
    if echo "${cmd_result}" | grep "echo"  && echo "${cmd_result}" | grep "curl" ;then
        return 0
    else
        echo ${cmd_result}
        return 1
    fi
}
#"
protect_replacement_cmd="echo"
protect_replacement_args="Don't play small smart"
#protect_replacement_args="RG9uJ3QgcGxheSBzbWFsbCBzbWFydAo= | ${real_cmd} -d"

#${protect_condition}
protect_cmd_exec(){
    # 执行替换的命令
    if [ -n "${protect_replacement_cmd}" ];then
        if [ -n "${protect_replacement_args}" ];then
            ${protect_replacement_cmd} ${protect_replacement_args}
        else
            ${protect_replacement_cmd} ${*}
        fi
    else
        if [ -n "${protect_replacement_args}" ];then
            ${real_cmd} ${protect_replacement_args}
        else
            echo '${real_cmd} ${*}'
        fi
    fi
}
if cmd_result=$(protect_cmd_check ${*});then
    protect_cmd_exec
else
    #${real_cmd} ${*}
    #OLD_IFS=${IFS}
    #export IFS=" "
    for ret_line in ${cmd_result};do
        echo ${ret_line}
    done
fi
