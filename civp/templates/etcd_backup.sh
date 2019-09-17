#!/bin/bash
set -e
exec >> /var/log/backup_etcd.log

Date=`date +%Y-%m-%d-%H-%M`
EtcdEndpoints="https://localhost:2379"
EtcdCmd="{{etcd_base_dir}}/etcdctl --cacert=/data/apps/config/etcd/ssl/etcd-root-ca.pem --cert=/data/apps/config/etcd/ssl/etcd-client-ca.pem --key=/data/apps/config/etcd/ssl/etcd-client-ca-key.pem"
BackupDir="/data/apps/data/backup/etcd"
BackupFile="snapshot.db.$Date"

echo "`date` backup etcd..."

export ETCDCTL_API=3
$EtcdCmd --endpoints $EtcdEndpoints snapshot save  $BackupDir/$BackupFile

echo  "`date` backup done!"
