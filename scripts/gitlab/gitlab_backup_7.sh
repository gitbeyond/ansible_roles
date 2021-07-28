#!/bin/bash
# editor: wanghaifeng@idstaff.com
# create date: 2020/12/22
# 备份gitlab数据
# gitlab-7.0.12 的版本


# 两种方式，第一种是指定每月固定时间的进行全备，比如每月10号
# 第二种是检查上一次全备的时间

# 示例: 下周三删除本周二的备份

#gitlab_backup_dir=/var/opt/gitlab/backup
gitlab_backup_dir=/home/backup
gitlab_repo_data_dir=/var/opt/gitlab/git-data/repositories
gitlab_backup_remote_dir=/home/bak/gitlab_68
gitlab_backup_keep_one_dir=/data/apps/data/backup/gitlab
# 这个目录下的是不删的,目前(2021/01/21)是定义每月15号一个全备
gitlab_season_bak_dir=/home/bak/seanson_bak/gitlab_68
gitlab_full_backup_day=0
backup_file_delete_day=$((gitlab_full_backup_day+1))
# 一周中的第几天
dt_w=$(date +%'w')
# 一年中的第几周
dt_W=$(date +%'W')
dt_d=$(date +%'d')
dt=$(date +'%Y%m%d%H%M%S')
gitlab_backup_log=/var/log/gitlab_backup_${dt_W}.log

lock_file=/var/log/.gitlab_backup.lock



write_log(){
    local log=$1
    if [ -e ${gitlab_backup_log} ];then
        :
    else
        local gitlab_backup_log_dir=$(dirname ${gitlab_backup_log})
        [ -d ${gitlab_backup_log_dir} ] || mkdir -p ${gitlab_backup_log_dir}
        touch ${gitlab_backup_log}
    fi
    echo "$(date) ${log}" >> ${gitlab_backup_log}
}

check_lock(){
    exec 3<> ${lock_file}

    if flock -n 3;then
        #echo "get ${lock_file} lock file."
        :
    else
        write_log "get lock file failed. now exit."
        exit 5
    fi
}

check_fs_size(){
    # 检测目标目录是否能够放得下要copy的文件
    # 定义一个额外的 5G 的空间
    local addition_size=$3
    addition_size=${addition_size:-5368709120}
    # 要copy的文件
    local file_name=$1
    # 文件copy的目标目录
    local fs_name=$2
    # 检查参数数量
    if [[ -n "${file_name}" && -n "${fs_name}" ]];then
        :
    else
        return 3
    fi

    if [ "${file_name}" == "${fs_name}" ];then
        # 源与目标一样时，返回2
        return 2
    fi
    
    if [ -d ${fs_name} ];then
        :
    else
        # ${fs_name} 不是目录时返回6
        return 6
    fi

    # 获取文件或目录的大小
    if [ -e ${file_name} ];then 
        if [ -f ${file_name} ];then
            local file_size=$(stat -c %s ${file_name})
        fi
        if [ -d ${file_name} ];then
            local file_size=$(du -bs ${file_name} |awk '{print $1}')
        fi
    else
        # ${file_name} 不存在时返回5
        return 5
    fi
    
    # 获取目标目录的剩余空间
    # 得到目标目标的设备号
    local fs_dev_num=$(stat -c '%d' ${fs_name})
    local all_mount_point=$(df |awk '{print $NF}' | tail -n +2)
    for p in ${all_mount_point};do
        # 比如目标目录的设备号与设备的设备号是否一致
        local p_dev_num=$(stat -c '%d' ${p})
        if [ "${fs_dev_num}" == "${p_dev_num}" ];then
            local fs_mount_dev=${p}
            break
        fi
    done
    # 获取文件系统剩余空间大小 字节
    local fs_free_space=$(df -B 1 ${fs_mount_dev} | tail -n 1 |awk '{print $4}')
    # 把文件大小加上5G
    local file_size=$((file_size+addition_size))
    if [ ${fs_free_space} -gt ${file_size} ];then
        return 0
    else
        return 1
    fi

}

#check_fs_size /etc/fstab /tmp 8000000000

gitlab_backup(){
    local git_repo_data_size=$(du -bs ${gitlab_repo_data_dir} |awk '{print $1}')
    git_repo_data_size=$((git_repo_data_size+5368709120))
    # 判断是否是全量备份日
    if [ ${dt_w} == ${gitlab_full_backup_day} ];then
        # 判断目标目录是否比当前数据大
        if check_fs_size ${gitlab_repo_data_dir} ${gitlab_backup_dir} ${git_repo_data_size};then
            /opt/gitlab/bin/gitlab-rake gitlab:backup:create
            if [ $? == 0 ];then
                write_log "/opt/gitlab/bin/gitlab-rake gitlab:backup:create successful."
            else
                write_log "/opt/gitlab/bin/gitlab-rake gitlab:backup:create failed."
            fi 
        else
            write_log "gitlab_backup_dir: ${gitlab_backup_dir} free space is less than gitlab_repo_data_dir:${gitlab_repo_data_dir}"
            return 10
        fi

    else
        # 这里备份是跳过仓库的备份
        if check_fs_size ${gitlab_repo_data_dir} ${gitlab_backup_dir};then
            /opt/gitlab/bin/gitlab-rake gitlab:backup:create SKIP=repositories
            if [ $? == 0 ];then
                write_log "/opt/gitlab/bin/gitlab-rake gitlab:backup:create SKIP=repositories successful."
            else
                write_log "/opt/gitlab/bin/gitlab-rake gitlab:backup:create SKIP=repositories failed."
            fi 
        else
            write_log "gitlab_backup_dir: ${gitlab_backup_dir} free space is less than gitlab_repo_data_dir:${gitlab_repo_data_dir}"
            return 10
        fi
    fi
    #local last_backup_file=$(ls -1 --sort=t ${gitlab_backup_dir}/*gitlab_backup.tar | tail -n 1)
    local last_backup_file=$(ls -1 --sort=t ${gitlab_backup_dir}/*gitlab_backup.tar | head -n 1)
    #last_backup_file_size=$(stat -c %s ${gitlab_backup_dir}/${last_backup_file})
    # local last_backup_file_full_name=${gitlab_backup_dir}/${last_backup_file}
    local last_backup_file_full_name=${last_backup_file}
    # 将备份copy至nfs目录上
    if check_fs_size ${last_backup_file_full_name} ${gitlab_backup_remote_dir};then
        # 远程目录上创建以当年第几个周命名的目录
        mkdir -p ${gitlab_backup_remote_dir}/${dt_W}
        # copy 到远程目录
        cp ${last_backup_file_full_name} ${gitlab_backup_remote_dir}/${dt_W}/
        write_log "cp ${last_backup_file_full_name} ${gitlab_backup_remote_dir}/${dt_W}/ successful."
    else
        write_log "gitlab_backup_remote_dir:${gitlab_backup_remote_dir} is less than last_backup_file_full_name:${last_backup_file_full_name}"
    fi

    # 删除nfs上的上一周的备份
    #local prev_week_num=$(date -d'-7day' +%W)
    local prev_week_num=$(date -d'-28day' +%W)
    if [ ${dt_w} == ${backup_file_delete_day} ];then
        if [ -d ${gitlab_backup_remote_dir}/${prev_week_num} ];then
            # 这里先不执行真正的删除操作，先只是记录日志
            write_log "rm -rf ${gitlab_backup_remote_dir}/${prev_week_num}"
            rm -rf ${gitlab_backup_remote_dir}/${prev_week_num}
        fi
    else
        :
    fi

    # 先删除本地的上一周的目录
    if [ ${dt_w} == ${gitlab_full_backup_day} ];then
        
        if [ -d ${gitlab_backup_keep_one_dir}/${prev_week_num} ];then
            rm -rf ${gitlab_backup_keep_one_dir}/${prev_week_num}
            write_log "rm -rf ${gitlab_backup_keep_one_dir}/${prev_week_num} successful."
        fi
    else
        :
    fi

    # 往本地目录保留一个全量备份
    if check_fs_size ${last_backup_file_full_name} ${gitlab_backup_keep_one_dir};then
        mkdir -p ${gitlab_backup_keep_one_dir}/${dt_W}
        mv ${last_backup_file_full_name} ${gitlab_backup_keep_one_dir}/${dt_W}
        write_log "mv ${last_backup_file_full_name} ${gitlab_backup_keep_one_dir}/${dt_W} successful."
    else
        write_log "gitlab_backup_keep_one_dir:${gitlab_backup_keep_one_dir} is less than last_backup_file_full_name:${last_backup_file_full_name}"  
    fi
}

gitlab_month_backup(){
    # 如果是15号之后的时间且是周一
    if [[ ${dt_d} -gt 15 && ${dt_w} == 1 ]];then
        local prev_week_num=$(date -d'-7day' +%W)
        local last_backup_file_full_name=$(ls -1 --sort=t ${gitlab_backup_remote_dir}/${prev_week_num}/*gitlab_backup.tar |head -n 1)
        mkdir -p ${gitlab_season_bak_dir}/${dt}
        mv ${last_backup_file_full_name} ${gitlab_season_bak_dir}/${dt}         
    else
        :
    fi    
}

check_lock
gitlab_backup
gitlab_month_backup
# 执行备份
#gitlab-backup create STRATEGY=copy

#gitlab-backup create

# 跳过 repositories 的备份

#gitlab-backup create SKIP=repositories


# /etc/gitlab/gitlab-secrets.json 和 /etc/gitlab/gitlab.rb 需要单独备份

# 另外还有 ssh 密钥，这里我猜想是gitlab 做CI/CD时访问别的机器的密钥

