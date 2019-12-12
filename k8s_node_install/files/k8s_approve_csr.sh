
kube_cmd=$1
kube_config=$2

# kubectl get csr |awk '/^node/{print $1}' |while read line; do  kubectl certificate approve ${line};done

${kube_cmd} --kubeconfig ${kube_config}  get csr |awk '/^node/{print $1}' |while read line; do 
    ${kube_cmd} --kubeconfig ${kube_config} certificate approve ${line}
done
