

rados_pools=$(ceph osd pool ls)

rbd_status(){
    local rbd_dev=${1}
    rbd status ${rbd_dev}
}
rbd_client_status(){
    for pool in ${rados_pools};do
        rbd_devs=$(rbd ls ${pool})
        for rbd_dev in ${rbd_devs};do
            rbd_status_result=$(rbd_status ${pool}/${rbd_dev})
            rbd_status_result_end_string=$(echo ${rbd_status_result} |awk '{print $NF}')
    	if [ "${rbd_status_result_end_string}" == "none" ];then
                :
            else
                echo "${pool}/${rbd_dev} ${rbd_status_result}"
            fi
        done
    done
}

cephfs_client_status(){
    ceph daemon mds.kvm5 session ls | jq '.[] | .inst,.client_metadata'
}
