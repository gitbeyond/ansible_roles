#!/bin/bash
# editor: haifengsss@163.com
# 2019/12/06
# 用来生成 kubeconfig 的脚本
# 可以生成 serviceAccount（比如 kubernetes 的 dashboard） 或者是 clusterRole 类型的 kubeconfig 

cert_dir=./ansible_k8s_certs
echo_black(){
    local str1=$1
    echo -e "\033[30m${str1}\033[0m"
}

echo_red(){
    local str1=$1
    echo -e "\033[31m${str1}\033[0m"
}
echo_green(){
    local str1=$1
    echo -e "\033[32m${str1}\033[0m"
}
echo_yellow(){
    local str1=$1
    echo -e "\033[33m${str1}\033[0m"
}

help_info(){
            echo_green "please add argument.
  --kube_cmd: kubectl position.
  --kubeconfig: the kubeconig for admission.
  --kube_sa_name: serviceAccount.
  --kube_user_name: user name.
  --kube_group_name: group name.
  --kube_cluster_role: clusterRole or role.
  --kube_ns: namespace.
  --kube_rb_name: rolebinding name.
  --kube_cluster_name: cluster name.
  --kube_api_server: apiserver address.
  --kube_root_ca: kubernetes root ca file.
  --kube_root_ca_key: kubernetes root ca key file.
  --kube_new_config: new kubeconfig name.
  --kube_cluster_priv: true or false. clusterrolebinding or rolebinding.
examples: 
  --kube_cmd /root/k8s_55/k8s/kubectl --kubeconfig /root/k8s_55/k8s/admin.kubeconfig --kube_sa_name dashboard-admin --kube_ns kube-system --kube_api_server https://10.111.36.70:7443 --kube_root_ca ./ansible_k8s_certs/k8s-root-ca.pem --kube_root_ca_key ./ansible_k8s_certs/k8s-root-ca-key.pem --kube_new_config ./dashboard-admin.kubeconfig --kube_cluster_role cluster-admin 

  --kube_cmd /root/k8s_55/k8s/kubectl --kubeconfig /root/k8s_55/k8s/admin.kubeconfig --kube_user_name uc-admin --kube_ns user-center --kube_api_server https://10.111.36.70:7443 --kube_root_ca ./ansible_k8s_certs/k8s-root-ca.pem --kube_root_ca_key ./ansible_k8s_certs/k8s-root-ca-key.pem --kube_new_config ./uc-admin.kubeconfig --kube_cluster_role admin 

"
    exit 0
}
	
while [[ $# -ge 1 ]]; do
    case $1 in
        --kube_cmd )
            kube_cmd=$2
            #echo "经过a"
            shift 2
            ;;
        --kubeconfig)
            kube_old_config=$2
            shift 2
            ;;
        --kube_sa_name )
            kube_sa_name=$2
            #echo "经过b"
            shift 2
            ;;
        --kube_user_name )
            kube_user_name=$2
            #echo "经过b"
            shift 2
            ;;
        --kube_group_name )
            kube_group_name=$2
            #echo "经过b"
            shift 2
            ;;
        --kube_cluster_role)
            kube_cluster_role=$2
            #echo "经过b"
            shift 2
            ;;
        --kube_ns)
            kube_ns=$2
            #echo "经过c"
            shift 2
            ;;
        --kube_rolebinding_name )
            kube_rb_name=$2
            shift 2
            ;;
        --kube_cluster_name )
            kube_cluster_name=$2
            shift 2
            ;;
        --kube_api_server )
            kube_api_server=$2
            shift 2
            ;;
        --kube_root_ca )
            kube_root_ca=$2
            shift 2
            ;;
        --kube_root_ca_key )
            kube_root_ca_key=$2
            shift 2
            ;;
        --kube_new_config )
            kube_new_config=$2
            shift 2
            ;;
        --kube_cluster_priv )
            kube_cluster_priv=$2
            shift 2
            ;;
        -h|--help)
            help_info
            shift
            ;;
        *)
            help_info
            #echo "please add argument."
            shift
            ;;
    esac
done


args=(
kube_cmd
kube_old_config
kube_sa_name
kube_user_name
kube_group_name
kube_ns
kube_rb_name
kube_cluster_name
kube_api_server
kube_root_ca
kube_root_ca_key
kube_new_config
kube_cluster_role
kube_cluster_priv
)
# 设置参数默认值
kube_cmd=${kube_cmd:-/usr/bin/kubectl}
kube_rb_name=${kube_rb_name:-${kube_sa_name}}
kube_cluster_name=${kube_cluster_name:-kubernetes}
kube_cluster_priv=${kube_cluster_priv:-true}
# 已有的与k8s集群通信的kubeconfig
kube_old_config=${kube_old_config:-~/.kube/config}

kube_group_name=${kube_group_name:-kubernetes}

if [ -n "${kube_sa_name}" ] && [ -n "${kube_user_name}" ];then
        echo_red "--kube_user_name ${kube_user_name} conflict --kube_sa_name ${kube_sa_name}."
        #exit 8
    #fi
fi



# 检查参数是否为 null
for arg in ${args[@]};do
    arg_null_num=0

    if [ -n "${!arg}" ];then
        echo_green "${arg}: ${!arg}"
    else
        echo_red "the ${arg} is null."
        #exit 2
        if [ "${arg}" == "kube_user_name" ] || [ "${arg}" == "kube_sa_name" ];then
            #if [ -n "${!arg}" ];then
            #    :
            #else
                arg_null_num=$((arg_null_num+1))
            #fi
        else
            echo_red "exit"
            exit 2
        fi
    fi

    if [ ${arg_null_num} -gt 1 ];then
        exit 3
    fi
done

# 检查文件路径是否正确，是否可执行
if [ -e ${kube_root_ca} ];then
    :
else
    echo_red "the ${kube_root_ca} isn't exist."
    exit 3
fi
# 检查证书与私钥是否匹配
if [ -n "${kube_user_name}" ];then
    if [ -e "${kube_root_ca_key}" ];then
        key_file_pubout=$(openssl pkey -in ${kube_root_ca_key} -pubout -outform pem | sha256sum )
        key_file_pubout=${key_file_pubout%\ *}
        crt_file_pubout=$(openssl x509 -in ${kube_root_ca} -pubkey -noout -outform pem | sha256sum )
        crt_file_pubout=${crt_file_pubout%\ *}
        if [ "${crt_file_pubout}" == "${key_file_pubout}" ];then
            :
        else
            echo_red "the ${kube_root_ca} with ${kube_root_ca_key} can't match."
            exit 9
        fi
        #openssl req -in CSR.csr -pubkey -noout -outform pem | sha256sum
    fi
fi

if [ -x ${kube_cmd%%\ *} ];then
    :
else
    echo_red "the ${kube_cmd} isn't execute."
    exit 5
fi

if [ -e ${kube_new_config} ];then
    echo_red "the ${kube_new_config} already exist."
    exit 6
fi


# 确定要创建的 rolebinding 类型
if [ ${kube_cluster_priv} == true ];then
    role_type=clusterrolebinding
else
    role_type=rolebinding
fi

check_file_exist(){
    local files=$1
    local cmd=$2
    if [ -e ${files} ];then
        echo_yellow "the ${files} already exist."
    else
        eval ${cmd}
    fi
}

create_cert(){
    [ -d ${cert_dir} ] || mkdir -p ${cert_dir}
    cd ${cert_dir}
    
    check_file_exist ${kube_user_name}.key "openssl genrsa -out ${kube_user_name}.key 2048"
    chmod 0700 ${kube_user_name}.key
    check_file_exist ${kube_user_name}.csr "openssl req -new -key ${kube_user_name}.key -out ${kube_user_name}.csr -subj '/CN=${kube_user_name}/O=${kube_group_name}'"
    check_file_exist ${kube_user_name}.crt "openssl x509 -req -in ${kube_user_name}.csr -CA ${kube_root_ca} -CAkey ${kube_root_ca_key} -CAcreateserial -out ${kube_user_name}.crt -days 3650"
    cd ..
}

create_sa(){
    echo_yellow "$kube_cmd --kubeconfig ${kube_old_config} create serviceaccount ${kube_sa_name} -n ${kube_ns}"
    $kube_cmd --kubeconfig ${kube_old_config} create serviceaccount ${kube_sa_name} -n ${kube_ns} 
    
    echo_yellow "$kube_cmd --kubeconfig ${kube_old_config} create ${role_type} ${kube_rb_name} --clusterrole=${kube_cluster_role} --serviceaccount=${kube_ns}:${kube_sa_name}"
    $kube_cmd --kubeconfig ${kube_old_config} -n ${kube_ns} create ${role_type} ${kube_rb_name} --clusterrole=${kube_cluster_role} \
      --serviceaccount=${kube_ns}:${kube_sa_name}
}

error_exit(){
    #expect_num=${expect_num:-0}
    #exit_num=${exit_num:-15}
    if [ $# -eq 2 ];then
        local expect_num=$1
        local exit_num=$2
        #if [ $? -ne ${expect_num} ];then
        #    echo_red "exit ${exit_num}"
        #    exit ${exit_num}
        #fi
        if [ ${expect_num} -ne 0 ];then
            if [ $? -eq 0 ];then
                echo_red "expect_num: ${expect_num}, exit ${exit_num}"
                exit ${exit_num}
            fi
        fi
    fi

    if [ $# -eq 1 ];then
        local exit_num=$1
    fi

    if [ $# -eq 0 ];then
        local exit_num=15
    fi
    if [ $? -ne 0 ];then
        echo_red "exit ${exit_num}"
        exit ${exit_num}
    fi
}

$kube_cmd --kubeconfig ${kube_old_config} -n ${kube_ns} get ${role_type} ${kube_rb_name}
rb_result=$?
#if [ "${sa_result}" == "0" ] && [ "${rb_result}" == "0" ];then
if [ "${rb_result}" == "0" ];then
    echo_red "the object already exist."
    #exit 7
else
    :
fi

# 设置根证书
echo_yellow "$kube_cmd config set-cluster ${kube_cluster_name} --embed-certs=true --server=${kube_api_server} \
  --certificate-authority=${kube_root_ca} --kubeconfig=${kube_new_config}"

$kube_cmd config set-cluster ${kube_cluster_name} --embed-certs=true --server=${kube_api_server} \
  --certificate-authority=${kube_root_ca} --kubeconfig=${kube_new_config}
# 如果 sa 的对象存在，则退出，不存在则创建
if [ -n "${kube_sa_name}" ];then
    $kube_cmd --kubeconfig ${kube_old_config} -n ${kube_ns} get sa ${kube_sa_name}
    error_exit 0 16
    #sa_result=$?
    #if [ ${sa_result} == 0 ];then
    #    echo_red "the object alread exist."
    #    exit 5
    #fi
    create_sa
    # 设置 sa token
    #sa_secret=$($kube_cmd -n ${kube_ns} get secret | awk "/^${kube_sa_name}\-token\-[^token]/{print $1}")
    sa_secret=$($kube_cmd --kubeconfig ${kube_old_config} -n ${kube_ns} get sa ${kube_sa_name} -o jsonpath={.secrets[0].name})
    sa_token=$(${kube_cmd} --kubeconfig ${kube_old_config} -n ${kube_ns} get secret ${sa_secret} -o jsonpath={.data.token} | base64 -d)
    
    set -e
    echo_yellow "${kube_cmd} config set-credentials ${kube_sa_name} --token=${sa_token} \
      --kubeconfig=${kube_new_config}"
    
    ${kube_cmd} config set-credentials ${kube_sa_name} --token=${sa_token} \
      --kubeconfig=${kube_new_config}
    # 设置 context
    echo_yellow "${kube_cmd} config set-context ${kube_sa_name} --cluster=${kube_cluster_name} \
      --user=${kube_sa_name} --kubeconfig=${kube_new_config}"
    
    ${kube_cmd} config set-context ${kube_sa_name} --cluster=${kube_cluster_name} \
      --user=${kube_sa_name} --kubeconfig=${kube_new_config}
    
    echo_yellow "${kube_cmd} config use-context ${kube_sa_name} --kubeconfig=${kube_new_config}"
    
    ${kube_cmd} config use-context ${kube_sa_name} --kubeconfig=${kube_new_config}

fi

if [ -n "${kube_user_name}" ];then
    create_cert
    cd ${cert_dir}
    set -e
    $kube_cmd --kubeconfig ${kube_old_config} -n ${kube_ns} create ${role_type} ${kube_rb_name} --clusterrole=${kube_cluster_role} --user=${kube_user_name}
    $kube_cmd config set-credentials ${kube_user_name} --embed-certs=true \
      --client-certificate=${kube_user_name}.crt \
      --client-key=${kube_user_name}.key \
      --kubeconfig ${kube_new_config}
    ${kube_cmd} config set-context ${kube_user_name}@${kube_cluster_name} --cluster=${kube_cluster_name} \
      --user=${kube_user_name} --kubeconfig=${kube_new_config}
    ${kube_cmd} config use-context ${kube_user_name}@${kube_cluster_name} --kubeconfig=${kube_new_config}
fi

#set -e



