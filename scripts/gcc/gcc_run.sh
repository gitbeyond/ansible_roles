#!/bin/bash

sou_file=$1
sou_file_dir=$(dirname $sou_file)
sou_base_file=$(basename ${sou_file})
tmp_dir=${sou_file_dir}/.tmp
tmp_sou_dir=${tmp_dir}/src
tmp_out_dir=${tmp_dir}/out
FTYPE=" C source"
dst_file=${sou_base_file%.*}


# 单文件：
# 多文件
# 多文件同时指定 -o 选项
sou_files=""
check_param(){
    while [[ $# -ge 1 ]]; do
        case $1 in
            -o)
                dst_file=$2
                #echo "经过a"
                shift 2
                ;;
            *)
                #help_info
                sou_files="${sou_files} ${1}"
                #echo "please add argument."
                shift
                ;;
        esac
    done
}

check_file_type(){
    local sou_file=$1
    # 判断文件类型是否是 c 的源代码文件
    local file_type=$(file ${sou_file} |awk -F":" '{print $NF}' | awk -F',' '{print $1}')
    if [ "${file_type}" == "${FTYPE}" ];then
        # 创建临时目录
        [ -d ${tmp_sou_dir} ] || mkdir -p ${tmp_sou_dir} 
        [ -d ${tmp_out_dir} ] || mkdir -p ${tmp_out_dir} 
        # 这里应该检查源文件是否有历史版本，有的话进行对比，是否发生了变化,如发生了变化，才进行编译
        # 但是这里的问题就是如何判定当前编译的文件跟源码是否匹配呢？
        # 复制一份源文件
        #cp ${sou_file} ${tmp_sou_dir}
    else
        echo "the ${sou_file} type isn't c lang source file."
        exit 6
    fi
}
check_files(){
    for sou_file in ${sou_files};do
        # 判断文件是否存在，存在则创建临时目录
        if [ -f ${sou_file} ];then
            check_file_type ${sou_file}
        else
            echo "the ${sou_file} isn't exist."
            exit 5
        fi
    done
}

gcc_compile_files(){
    #gcc -std=c99 -o ${tmp_dir}/${dst_file} ${sou_file}
    gcc -o ${tmp_out_dir}/${dst_file} ${sou_files}
}
gcc_exec_file(){
    ${tmp_out_dir}/${dst_file}
}

main(){
    check_param ${@}
    echo ${sou_files}
    echo ${dst_file}
    check_files
    gcc_compile_files
    gcc_exec_file
    exit 0
}
main ${@}
