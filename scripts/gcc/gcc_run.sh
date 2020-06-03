#!/bin/bash

sou_file=$1
sou_file_dir=$(dirname $sou_file)
sou_base_file=$(basename ${sou_file})
tmp_dir=${sou_file_dir}/.tmp
tmp_sou_dir=${tmp_dir}/src
tmp_out_dir=${tmp_dir}/out
FTYPE=" C source"

# 判断文件是否存在，存在则创建临时目录
if [ -f ${sou_file} ];then
    :
else
    echo "the ${sou_file} isn't exist."
    exit 5
fi

# 判断文件类型是否是 c 的源代码文件
file_type=$(file ${sou_file} |awk -F":" '{print $NF}' | awk -F',' '{print $1}')
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

dst_file=${sou_base_file%.*}
#gcc -std=c99 -o ${tmp_dir}/${dst_file} ${sou_file}
gcc -o ${tmp_out_dir}/${dst_file} ${sou_file}

${tmp_out_dir}/${dst_file}
