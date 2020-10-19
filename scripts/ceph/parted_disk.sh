# 此脚本是用来创建 osd 的，这里显式指定了 --block.db 等参数
#devs=(sdb sdc sdd)
#devs=(sdb )
devs=(sdb sdc sdd)

for disk in ${devs[*]};do
    parted /dev/${disk} mklabel gpt 
    parted /dev/${disk} mkpart primary 0% 30GB 
    parted /dev/${disk} mkpart primary 30GB 100%
    pvcreate /dev/${disk}1
    vgcreate ceph-${disk} /dev/${disk}1
    lvcreate -n ceph-block.db -L 2048m ceph-${disk}
    lvcreate -n ceph-block.wal -L 2048m ceph-${disk}
    ceph-volume lvm prepare --bluestore --data /dev/${disk}2 --block.db ceph-${disk}/ceph-block.db --block.wal ceph-${disk}/ceph-block.wal &> /tmp/ceph-prepare-${disk}.out
    #grepvim
    osd_num=$(grep -o "osd.[0-9]\{1,3\}" /tmp/ceph-prepare-${disk}.out | head -n 1 |awk -F'.' '{print $NF}')
    osd_uuid=$(grep client.bootstrap-osd /tmp/ceph-prepare-${disk}.out |head -n 1 |awk '{print $NF}')
    ceph-volume lvm activate --bluestore ${osd_num} ${osd_uuid}

done
