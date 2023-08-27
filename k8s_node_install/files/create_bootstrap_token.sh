#!/bin/bash
#
set -euo pipefail
#
TOKEN_PUB=$1
TOKEN_SECRET=$2
kube_cmd=$3
kube_config=$4

kube_ctl="${kube_cmd} --kubeconfig ${kube_config}"
k8s_boot_token_name=bootstrap-token-${TOKEN_PUB}

if ${kube_ctl} -n kube-system get secret ${k8s_boot_token_name}; then
    echo "the secret ${k8s_boot_token_name} already exist."
else

    #${kube_cmd} --kubeconfig ${kube_config} -n kube-system create secret generic bootstrap-token-${TOKEN_PUB} \
    ${kube_ctl} -n kube-system create secret generic bootstrap-token-${TOKEN_PUB} \
        --type 'bootstrap.kubernetes.io/token' \
        --from-literal description="cluster bootstrap token" \
        --from-literal token-id=${TOKEN_PUB} \
        --from-literal token-secret=${TOKEN_SECRET} \
        --from-literal usage-bootstrap-authentication=true \
        --from-literal usage-bootstrap-signing=true
    echo "changed"
fi

if ${kube_ctl} get clusterrolebinding kubelet-bootstrap; then
    echo "the clusterrolebinding kubelet-bootstrap already exist."
else
    #${kube_cmd} --kubeconfig ${kube_config} \
    ${kube_ctl} create clusterrolebinding kubelet-bootstrap \
        --clusterrole system:node-bootstrapper \
        --user kubelet-bootstrap \
        --group system:bootstrappers
    echo "changed"
fi
#####
if ${kube_ctl} get clusterrolebinding auto-approve-csrs-for-group; then
    :
else
    # 自动批复 "system:bootstrappers" 的CSR
    ${kube_ctl} create clusterrolebinding auto-approve-csrs-for-group \
        --clusterrole=system:certificates.k8s.io:certificatesigningrequests:nodeclient \
        --user=kubelet-bootstrap \
        --group=system:bootstrappers
    echo "changed"
fi
#####
if ${kube_ctl} get clusterrolebinding auto-approve-renewals-for-nodes;then
    :
else
    # 自动批复"system:nodes"组的CSR续约
    ${kube_ctl} create clusterrolebinding auto-approve-renewals-for-nodes \
        --clusterrole=system:certificates.k8s.io:certificatesigningrequests:selfnodeclient \
        --group=system:nodes
    echo "changed"
fi

#${kube_cmd} --kubeconfig ${kube_config} \
#    create clusterrolebinding kubeadm:kubelet-bootstrap \
#    --clusterrole system:node-bootstrapper \
#    --group system:bootstrappers

