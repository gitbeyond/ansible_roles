#!/bin/bash
export PATH=/data/apps/opt/etcd:$PATH
export ETCDCTL_API=3
export ETCDCTL_CA_FILE={{etcd_conf_dir}}/ssl/etcd-root-ca.pem
export ETCDCTL_KEY_FILE={{etcd_conf_dir}}/ssl/etcd-client-ca-key.pem
export ETCDCTL_CERT_FILE={{etcd_conf_dir}}/ssl/etcd-client-ca.pem
