
# 自动批复 "system:bootstrappers" 组的所有CSR
kubectl create clusterrolebinding auto-approve-csrs-for-group \
    --clusterrole=system:certificates.k8s.io:certificatesigningrequests:nodeclient \
    --user=kubelet-bootstrap \
    --group=system:bootstrappers

# 自动批复"system:nodes"组的CSR续约请求
kubectl create clusterrolebinding auto-approve-renewals-for-nodes \
    --clusterrole=system:certificates.k8s.io:certificatesigningrequests:selfnodeclient \
    --group=system:nodes
