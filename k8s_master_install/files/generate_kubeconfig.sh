#!/bin/bash
echo "${USER}"
k8s_kubeconfig=$1
k8s_cluster_name=$2
k8s_root_ca=$3
k8s_master_ha_vip=$4
k8s_master_ha_port=$5

k8s_user=$6
k8s_client_cert=$7
k8s_client_key=$8
kube_cmd=$9

${kube_cmd} config set-cluster ${k8s_cluster_name} --embed-certs=true \
  --certificate-authority=${k8s_root_ca} --server="https://${k8s_master_ha_vip}:${k8s_master_ha_port}" \
  --kubeconfig=${k8s_kubeconfig}

${kube_cmd} config set-credentials ${k8s_user} --embed-certs=true \
  --client-certificate=${k8s_client_cert} --client-key=${k8s_client_key} \
  --kubeconfig=${k8s_kubeconfig}

${kube_cmd} config set-context ${k8s_user}@${k8s_cluster_name} --cluster=${k8s_cluster_name} \
  --user=${k8s_user} \
  --kubeconfig=${k8s_kubeconfig}

${kube_cmd} config use-context ${k8s_user}@${k8s_cluster_name} \
  --kubeconfig=${k8s_kubeconfig}

