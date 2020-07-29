#!/bin/bash
# 
# helm 使用 helm upgrade -i --dry-run --debug  harbor . 1> yaml/all.yaml 2> yaml/cmd_error.txt
# 生成相关的 yaml 文件
# 脚本的作用是将一个 helm 生成的 yaml 分别写至各自的目录文件中

source_file=all.yaml


all_files_name=$(grep -n "# Source" ${source_file})

#echo ${all_files_name}

all_files_head=$(grep -n "^---$" ${source_file})

#for y_file in ${all_files_name};do

grep -n "# Source" ${source_file} | while read y_file; do
    # 获取行号
    #y_file_line_num=$(grep -n "${y_file}" ${source_file} |awk -F: '{print $1}')
    y_file_line_num=$(echo "${y_file}" |awk -F: '{print $1}')
    y_file_begin_line_num=$((y_file_line_num-1))

    # 获取文件名和目录名
    y_filename=$(echo "${y_file}" | awk -F/ '{print $NF}')
    y_dirname=$(echo "${y_file}" | awk -F/ '{print $(NF-1)}')

    tmp_num=0
    # 通过 --- 获取结束的行号
    for y_head in ${all_files_head};do
        # 
        y_head_line_num=$(echo ${y_head} | awk -F: '{print $1}')
        # 这里判断一下，如果行号匹配了，把临时变量加一下，然后获取下一次循环的结果
        if [ ${y_head_line_num} == ${y_file_begin_line_num} ];then
            tmp_num=$((tmp_num+1))
            continue
        fi
        # 获取到结果后就退出,这个结果是 --- 的上一行
        # 1. --- 
        # 2. # Source: Source: harbor/templates/core/core-svc.yaml
        # 3. name: sj
        # 4. age: 32
        # 5. ---
        # 那么得到的是 4 ，这里已经直接减1了

        if [ ${tmp_num} -eq 1 ];then
            y_file_end_line_num=$((y_head_line_num-1))
            break
        fi
    done

    # 如果开始行号比结束行号小，就退出
    # 最后一行的情况下，会发生这个情况，因为上次循环的 y_head_line_num 没有清空，所以这里判断一下
    if [ ${y_file_end_line_num} -lt ${y_file_begin_line_num} ];then
        break
    fi
    
    echo "y_file_begin_line_num ${y_file_begin_line_num}"
    echo "y_file_end_line_num ${y_file_end_line_num}"
    [ -d ${y_dirname} ] || mkdir ${y_dirname}
    # 使用 sed 命令截取相关行，重定向至文件
    echo "sed -n '${y_file_begin_line_num},${y_file_end_line_num}p' ${source_file} > ${y_dirname}/${y_filename}"
    sed -n "${y_file_begin_line_num},${y_file_end_line_num}p" ${source_file} > ${y_dirname}/${y_filename}
#done
done
