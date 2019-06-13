#!/bin/bash
#export PATH={{ansible_env.PATH}}
. /etc/profile
. /etc/bashrc

source_file=$2
#target_dir=$2
#target_dir=/data3/apps/data/jenkins_data
target_dir=$3
backup_num=10
dt=$(date +%Y%m%d%H%M)
jenkins_home_dir=/data/apps/data/jenkins
project_name=$1
#source_dir=$1

#cd ${jenkins_home_dir}/jobs/${project_name}/builds
#lastSuccessfulBuild=$(ls -l ${jenkins_home_dir}/jobs/${project_name}/builds/lastSuccessfulBuild |awk '{print $NF}')
lastSuccessfulBuild=$BUILD_NUMBER
#project_dir=${jenkins_home_dir}/workspace/${project_name}

[ -e ${target_dir} ] || mkdir ${target_dir}
#if [ -d ${project_dir}/target ];then
#    cp -r ${project_dir}/target/${source_file} ${target_dir}/${project_name}/${source_file}_${lastSuccessfulBuild}
#else if [ -e ${project_dir}/${source_file} ];then
#    cp -r ${project_dir}/${source_file} ${target_dir}/${project_name}/${source_file}_${lastSuccessfulBuild}
#else
#    echo "the ${source_file} is not exist!"
#fi
#cp -r ${source_file} ${target_dir}/${project_name}/${source_file}_${lastSuccessfulBuild}
source_base_file=$(basename ${source_file})
if [ -e ${target_dir}/${source_base_file}_${lastSuccessfulBuild} ];then
    echo "the ${target_dir}/${source_base_file}_${lastSuccessfulBuild} exist."
else
    cp -r ${source_file} ${target_dir}/${source_base_file}_${lastSuccessfulBuild}
fi

cd ${target_dir}
old_file=$(ls -c1 |tail -n +11)
echo "rm -rf ${old_file}"
rm -rf ${old_file}

cd ${target_dir} && ls

