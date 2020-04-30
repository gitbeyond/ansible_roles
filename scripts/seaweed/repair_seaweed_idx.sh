#!/bin/bash
set -e 
volume_data_dir=/data/apps/data/seaweed-volume
weed_cmd=/data/apps/opt/seaweed/weed
weed_user=seaweed

fix_idx(){
    cd ${volume_data_dir}
    ls *.dat | while read line;do
        file_name=${line%.*}
        #echo ${file_name}
        file_name_arr=(${file_name/_/ }) 
        if [ ${#file_name_arr[@]} -eq 1 ];then
            echo "${weed_cmd} fix -dir ${volume_data_dir} -volumeId ${file_name_arr}"
            ${weed_cmd} fix -dir ${volume_data_dir} -volumeId ${file_name_arr}
        else
            collection=${file_name_arr[0]}
            volume_id=${file_name_arr[1]}
            echo "${weed_cmd} fix -dir ${volume_data_dir} -collection ${collection} -volumeId ${volume_id}"
            ${weed_cmd} fix -dir ${volume_data_dir} -collection ${collection} -volumeId ${volume_id}
        fi
        chown ${weed_user}:${weed_user} *.idx
        #echo "${collection} ${volume_id}"
    done
}

fix_idx
