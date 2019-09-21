TOKEN_PUB=$1
TOKEN_SECRET=$2
kube_cmd=$3
kube_config=$4

${kube_cmd} --kubeconfig ${kube_config} -n kube-system create secret generic bootstrap-token-${TOKEN_PUB} \
        --type 'bootstrap.kubernetes.io/token' \
        --from-literal description="cluster bootstrap token" \
        --from-literal token-id=${TOKEN_PUB} \
        --from-literal token-secret=${TOKEN_SECRET} \
        --from-literal usage-bootstrap-authentication=true \
        --from-literal usage-bootstrap-signing=true

${kube_cmd} --kubeconfig ${kube_config} \
    create clusterrolebinding kubeadm:kubelet-bootstrap \
    --clusterrole system:node-bootstrapper \
    --group system:bootstrappers
