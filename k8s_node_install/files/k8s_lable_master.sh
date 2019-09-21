
k8s_host=$1
. ~/.bashrc

kubectl label node ${k8s_host} node-role.kubernetes.io/master=
#kubectl label node k8s-3.geotmt.com node-role.kubernetes.io/master-
kubectl taint nodes ${k8s_host} node-role.kubernetes.io/master=:NoSchedule
