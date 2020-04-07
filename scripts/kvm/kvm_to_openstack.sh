#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
#declare -A a
# 此脚本的作用是分析 qemu 的 xml 文件，然后将其上传至 ceph 当中, 然后调用 openstack 命令创建卷信息等等
# 并未进行有效的测试
openstack_pass_file=/root/sch_openrc.sh
source ${openstack_pass_file}
qemu_file=es_1.xml
boot_dev=vda

#other_disk=($(xmllint --xpath '/domain/devices/disk/target[@dev!="vda"]/../source/@name' ${qemu_file}))
other_disk=($(xmllint --xpath '/domain/devices/disk/target/../source/@name' ${qemu_file}))
other_dev=($(xmllint --xpath '/domain/devices/disk[@device="disk"]/target/@dev' ${qemu_file}))
instance_name=$( xmllint --xpath '/domain/name/text()' ${qemu_file})
cinder_pool=volumes
#vda=$(xmllint --xpath '/domain/devices/disk/target[@dev="vda"]/../source/@name' ${qemu_file})
#echo ${vda}
#eval ${vda}
#vda=${name}
#echo ${vda}
#echo "--------------"
dev_num=${#other_disk[@]}
if [ ! -e ${qemu_file} ];then
    echo "${qemu_file} is not exists."
    exit 4
fi
#echo ${dev_num}
#echo ${other_disk[@]}
#echo ${other_disk[0]}
#echo ${other_dev[@]}
#declare -A dev_group
#rbd info ${vda}

dev_group=()
for((i=0;i<${dev_num};i++));do

    eval ${other_disk[${i}]}
    eval ${other_dev[${i}]}
    dev_group[${i}]=${dev}
    eval ${dev}=${name}
    echo ${vdb}
done
for ((i=0;i<${dev_num};i++));do
    echo ${dev_group[${i}]} == ${!dev_group[${i}]}
    dev_name=${dev_group[${i}]}
    disk_name=${!dev_group[${i}]}
    disk_basename=$(basename ${disk_name})
    #rbd du ${!dev_group[${i}]} | awk -vdisk_basename=${disk_basename} '{if($1==disk_basename){print $2}}'
    disk_size=$(rbd du ${!dev_group[${i}]} | awk -vdisk_basename=${disk_basename} '{if($1==disk_basename){
        len=length($2);
        size=substr($2,0,len-1);
        unit=substr($2,len);
        if(unit=="M"){
           printf ("%d\n" ,size/1024)
        }else{
           print size}
        }}')
    if [ ${dev_name} == "${boot_dev}" ];then
        # create volume for bootable
        #echo "new_volume_id=$(openstack volume create \"${instance_name}_${dev_name}\" -f shell --size ${disk_size}  
        #    --description \"${instance_name}_${dev_name}\" --bootable | grep \"^id\")"
        echo "openstack volume create \"${instance_name}_${dev_name}\" -f shell --size ${disk_size} --description \"${instance_name}_${dev_name}\" --bootable | grep \"^id\""
        new_volume_id=$(openstack volume create "${instance_name}_${dev_name}" -f shell --size ${disk_size} --description "${instance_name}_${dev_name}" --bootable | grep "^id")
        echo "get new_volume_id: ${new_volume_id}"
    else
        # create volume not bootable
        #echo "new_volume_id=$(openstack volume create \"${instance_name}_${dev_name}\" -f shell --size ${disk_size} 
        #    --description \"${instance_name}_${dev_name}\" | grep \"^id\")"
        echo "openstack volume create \"${instance_name}_${dev_name}\" -f shell --size ${disk_size} --description \"${instance_name}_${dev_name}\" | grep \"^id\""
        new_volume_id=$(openstack volume create "${instance_name}_${dev_name}" -f shell --size ${disk_size} --description "${instance_name}_${dev_name}" | grep "^id")  
        echo "get new_volume_id: ${new_volume_id}"
    fi
    echo "eval ${new_volume_id}"
    eval ${new_volume_id}
    # id="uuid"
    new_volume_name="volume-${id}"
    # rename volume to volume_tmp
    sleep 5
    if ! rbd info ${cinder_pool}/${new_volume_name} &> /dev/null;then
        echo "${cinder_pool}/${new_volume_name} is not exists." 
        exit 6
    fi
    echo "rbd mv ${cinder_pool}/${new_volume_name} ${cinder_pool}/${new_volume_name}_tmp"
    rbd mv ${cinder_pool}/${new_volume_name} ${cinder_pool}/${new_volume_name}_tmp
    if [ $? != 0 ];then
        echo "no ${new_volume_name}. create volume failed. " 
        exit 5
    fi
    # 将原来 kvm 实例的卷 cp 成刚才新建的卷的名字
    echo "rbd cp ${disk_name} ${cinder_pool}/${new_volume_name}"
    rbd cp ${disk_name} ${cinder_pool}/${new_volume_name}

done

