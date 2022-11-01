#!/bin/bash
# editor: haifengsss@163.com
# 2019/12/06
# 用来生成 kubeconfig 的脚本
# 可以生成 serviceAccount（比如 kubernetes 的 dashboard） 或者是 clusterRole 类型的 kubeconfig 
set -euo pipefail

cert_dir="./ansible_k8s_certs"
# 变量默认值
kube_cmd=""
kube_cluster_name="kubernetes"
kube_cluster_priv=true
# 已有的与k8s集群通信的kubeconfig
kube_old_config=""
kube_sa_name=""
kube_user_name=""
kube_group_name=""
kube_cluster_role=""
# 不指定时失败，而不是使用默认的 default
kube_ns=""
kube_api_server=""
kube_root_ca=""
kube_root_ca_key=""
# 要生成的 kubeconfig 的路径
kube_new_config=""
kube_group_name="kubernetes"
kube_rb_name=""
role_type="rolebinding"

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
  Created a serviceAccount in kubeconfig:
    $0 --kube_cmd /root/k8s_55/k8s/kubectl --kubeconfig /root/k8s_55/k8s/admin.kubeconfig --kube_sa_name dashboard-admin --kube_ns kube-system --kube_api_server https://10.111.36.70:7443 --kube_root_ca ./ansible_k8s_certs/k8s-root-ca.pem --kube_root_ca_key ./ansible_k8s_certs/k8s-root-ca-key.pem --kube_new_config ./dashboard-admin.kubeconfig --kube_cluster_role cluster-admin 
 
  创建一个拥有集群管理权限的kubeconfig
   $0 --kube_cmd /root/k8s_55/k8s/kubectl --kubeconfig /root/k8s_55/k8s/admin.kubeconfig --kube_user_name uc-admin --kube_ns user-center --kube_api_server https://10.111.36.70:7443 --kube_root_ca ./ansible_k8s_certs/k8s-root-ca.pem --kube_root_ca_key ./ansible_k8s_certs/k8s-root-ca-key.pem --kube_new_config ./uc-admin.kubeconfig --kube_cluster_role admin --kube_rb_name uc-admin

  创建一个拥有名称空间级别管理权限的kubeconfig
   $0 --kube_cmd /root/k8s_55/k8s/kubectl --kubeconfig /root/k8s_55/k8s/admin.kubeconfig --kube_user_name uc-admin --kube_ns user-center --kube_api_server https://10.111.36.70:7443 --kube_root_ca ./ansible_k8s_certs/k8s-root-ca.pem --kube_root_ca_key ./ansible_k8s_certs/k8s-root-ca-key.pem --kube_new_config ./uc-admin.kubeconfig --kube_cluster_role admin --kube_rb_name uc-admin --kube_cluster_priv false

  Create a user certificate in kubeconfig:
    $0 --kube_user_name ns1-admin --kube_ns ns1 --kube_api_server https://10.111.36.70:7443 --kube_root_ca /tmp/k8s/k8s-root-ca.pem --kube_root_ca_key /tmp/k8s/k8s-root-ca-key.pem --kube_new_config ns1-admin.kubeconfig --kube_cluster_role admin --kube_rb_name ns1-admin

  创建一个全局只读，同时可以exec pod的kubeconfig:
    $0 --kube_cmd /usr/bin/kubectl --kubeconfig=${KUBECONFIG} --kube_sa_name dashboard-view-exec --kube_ns kube-system --kube_api_server https://10.6.56.10:7443 --kube_root_ca /tmp/kubernetes/ca.crt --kube_root_ca_key /tmp/kubernetes/ca.key --kube_new_config /tmp/dashboard-view-exec.kubeconfig --kube_cluster_role view-with-exec

生成文件:
  ansible_k8s_certs dir
  clusterrolebinding 或者 rolebinding，取决于是否指定了 --kube_cluster_priv 
  新的kubeconfig文件
  serviceAccount，取决于是否指定了--kube_sa_name

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
        --kube_rb_name )
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
set_default_args(){
    #kube_cmd=${kube_cmd:-/usr/bin/kubectl}
    kube_rb_name=${kube_rb_name:-${kube_sa_name}}
    # 确定要创建的 rolebinding 类型
    if [ "${kube_cluster_priv}" == "true" ];then
        role_type=clusterrolebinding
    fi
    # 不为空时检测是否存在
    # 为空时应该会直接使用默认的 KUBECONFIG 或 ~/.kube/config
    if [ -n "${kube_old_config}" ]; then
        if [ -r "${kube_old_config}" ]; then
            :
        else
            if [ "${kube_old_config}" == '/tmp/.null' ]; then
                echo_red "please provide a kubeconfig file."
            else
                echo_red "the kubeconfig ${kube_old_config} isn't exist or isn't readable."
            fi
            exit 11
        fi
    else
        # KUBECONFIG 是否有值
        if [ -n "${KUBECONFIG}" ]; then
            # 是否可读
            if [ -r "${KUBECONFIG}" ]; then 
                # 是否与默认的值一致
                # if [ "${KUBECONFIG}" == "${HOME}/.kube/config" ]; then
                kube_old_config="${KUBECONFIG}"
                # fi
            else
                # 不让读取时，设置为空
                KUBECONFIG=""
                # 然后递归
                set_default_args
            fi
        elif [ -r "${HOME}/.kube/config" ]; then
            KUBECONFIG="${HOME}/.kube/config"
        else
            # 如果 KUBECONFIG 和 ~/.kube/config都读不到，那么就设置成一个不存在的路径
            # 然后递归报错
            kube_old_config="/tmp/.null"
            set_default_args
        fi
    fi
    # 检测 kube_cmd
    if [ -n "${kube_cmd}" ]; then
        if [ -x "${kube_cmd}" ]; then
            :
        else
            echo_red "the ${kube_cmd} isn't exist or isn't executable."
            exit 12
        fi
    else
        # 不存在时，从PATH中获取，然后调用自身进行检测
        kube_cmd=$(which kubectl 2>/dev/null || /bin/true)
        set_default_args
    fi
    # 检查 kube_new_config 变量
    if [ -e "${kube_new_config}" ];then
        echo_red "the ${kube_new_config} already exist."
        exit 6
    else
        if [[ "${kube_new_config}" =~ ^/ ]];then
            :
        else
            kube_new_config_base_name=$(basename "${kube_new_config}")
            kube_new_config="${PWD}/${kube_new_config_base_name}"
        fi
    fi
}


check_sa_and_user_name(){
    if [[ -n "${kube_sa_name}" && -n "${kube_user_name}" ]];then
        echo_red "--kube_user_name ${kube_user_name} conflict --kube_sa_name ${kube_sa_name}."
        #exit 8
    fi
}


check_args_has_null(){
    # 检查参数是否为 null
    for arg in ${args[@]};do
        arg_null_num=0
    
        if [ -n "${!arg}" ];then
            echo_green "${arg}: ${!arg}"
        else
            echo_red "the ${arg} is null."
            #exit 2
            if [[ "${arg}" == "kube_user_name" || "${arg}" == "kube_sa_name" ]];then
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
}

check_files_is_exist(){
    # 检查文件路径是否正确，是否可执行
    local files="${kube_root_ca} ${kube_root_ca_key}"
    for f in ${files}; do
        if [ -e "${f}" ];then
            :
        else
            echo_red "the ${f} isn't exist."
            exit 3
        fi
    done

    # if [ -x ${kube_cmd%%\ *} ];then
    #     :
    # else
    #     echo_red "the ${kube_cmd} isn't execute."
    #     exit 5
    # fi
    # check kube_new_config
    
}
check_ca_and_key_is_match(){
    # 检查证书与私钥是否匹配
    local key_file_pubout="" crt_file_pubout=""
    if [ -n "${kube_user_name}" ];then
        if [ -e "${kube_root_ca_key}" ];then
            key_file_pubout=$(openssl pkey -in "${kube_root_ca_key}" -pubout -outform pem | sha256sum )
            key_file_pubout=${key_file_pubout%\ *}
            crt_file_pubout=$(openssl x509 -in "${kube_root_ca}" -pubkey -noout -outform pem | sha256sum )
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
}

# 执行所有检查项的函数
check_args(){
    set_default_args
    check_sa_and_user_name
    check_args_has_null
    check_files_is_exist
    check_ca_and_key_is_match
}
# 执行检测
check_args

# 如果文件不存在的话，就执行一个命令
file_exist_or_cmd(){
    local file=$1
    local cmd="$2"
    if [ -e "${file}" ];then
        echo_yellow "the ${file} already exist."
    else
        eval "${cmd}"
    fi
}

# 创建自签证书
create_cert(){
    [ -d ${cert_dir} ] || mkdir -p ${cert_dir}
    cd ${cert_dir}
    # 生成私钥
    file_exist_or_cmd "${kube_user_name}.key" "openssl genrsa -out ${kube_user_name}.key 2048"
    chmod 0700 "${kube_user_name}.key"
    # 生成证书签署请求
    file_exist_or_cmd "${kube_user_name}.csr" "openssl req -new -key ${kube_user_name}.key -out ${kube_user_name}.csr -subj '/CN=${kube_user_name}/O=${kube_group_name}'"
    # 使用k8s的ca签署证书
    file_exist_or_cmd "${kube_user_name}.crt" "openssl x509 -req -in ${kube_user_name}.csr -CA ${kube_root_ca} -CAkey ${kube_root_ca_key} -CAcreateserial -out ${kube_user_name}.crt -days 3650"
    cd -
}

create_sa(){
    echo_yellow "$kube_cmd --kubeconfig ${kube_old_config} get serviceaccount ${kube_sa_name} -n ${kube_ns}"
    local get_sa_ret_code=0 get_rb_ret_code=0
    $kube_cmd --kubeconfig ${kube_old_config} get serviceaccount "${kube_sa_name}" -n "${kube_ns}" || get_sa_ret_code=$?
    # 存在即跳过
    if [ ${get_sa_ret_code} == 0 ];then
        :
    else
        echo_yellow "$kube_cmd --kubeconfig ${kube_old_config} create serviceaccount ${kube_sa_name} -n ${kube_ns}"
        # 此处可以考虑添加 label
        $kube_cmd --kubeconfig ${kube_old_config} create serviceaccount "${kube_sa_name}" -n "${kube_ns}"
    fi
    # 创建 rolebinding
    echo_yellow "$kube_cmd --kubeconfig ${kube_old_config} get ${role_type} ${kube_rb_name}"
    $kube_cmd --kubeconfig ${kube_old_config} -n "${kube_ns}" get ${role_type} "${kube_rb_name}" || get_rb_ret_code=$?
    # 不存在即创建
    if [ ${get_rb_ret_code} == 0 ];then
        :
    else
        echo_yellow "$kube_cmd --kubeconfig ${kube_old_config} create ${role_type} ${kube_rb_name} --clusterrole=${kube_cluster_role} --serviceaccount=${kube_ns}:${kube_sa_name}"
        $kube_cmd --kubeconfig ${kube_old_config} -n "${kube_ns}" create ${role_type} "${kube_rb_name}" --clusterrole="${kube_cluster_role}" \
          --serviceaccount="${kube_ns}:${kube_sa_name}"
    fi
}

# 这个函数是当一个命令执行完之后，来判断是否需要退出的
# $1 是期望的退出码
# $2 是退出时使用的退出码
# 这个函数在 set -e时没法正常使用，需要做出修改, 目前没有使用
error_exit(){
    local last_cmd_ret_code=$?
    #expect_num=${expect_num:-0}
    #exit_num=${exit_num:-15}
    if [ $# -eq 2 ];then
        local expect_num=$1 exit_num=$2
        #if [ $? -ne ${expect_num} ];then
        #    echo_red "exit ${exit_num}"
        #    exit ${exit_num}
        #fi
        # 如果期望状态码不等于 0 
        if [ ${expect_num} -ne 0 ];then
            # 如果实际退出码等于 0，那么就退出
            if [ ${last_cmd_ret_code} -eq 0 ];then
                echo_red "expect_num: ${expect_num}, exit ${exit_num}"
                exit ${exit_num}
            fi
        else
            :
        fi
    fi
    # 只有一个参数时，其表示，退出码值
    if [ $# -eq 1 ];then
        local exit_num=$1
    fi
    # 一个参数也没有时，默认退出码为 15
    if [ $# -eq 0 ];then
        local exit_num=15
    fi
    # 没有提供 期望的状态码时，则期望的值为0
    if [ ${last_cmd_ret_code} -ne 0 ];then
        echo_red "exit ${exit_num}"
        exit ${exit_num}
    fi
}

# $kube_cmd --kubeconfig ${kube_old_config} -n ${kube_ns} get ${role_type} ${kube_rb_name}
# rb_result=$?
# #if [ "${sa_result}" == "0" ] && [ "${rb_result}" == "0" ];then
# if [ "${rb_result}" == "0" ];then
#     echo_red "the object already exist."
#     #exit 7
# else
#     :
# fi

# 为新的kubeconfig设置根证书
kubeconfig_set_root_ca(){
    
    echo_yellow "$kube_cmd config set-cluster ${kube_cluster_name} --embed-certs=true --server=${kube_api_server} \
        --certificate-authority=${kube_root_ca} --kubeconfig=${kube_new_config}"

    $kube_cmd config set-cluster ${kube_cluster_name} --embed-certs=true --server=${kube_api_server} \
        --certificate-authority=${kube_root_ca} --kubeconfig=${kube_new_config}
}



# 如果 sa 的对象存在，则退出，不存在则创建
kubeconfig_set_sa_token(){
    local sa_secret="" sa_token=""
    create_sa
    # 设置 sa token
    # 获取secret name
    sa_secret=$($kube_cmd --kubeconfig ${kube_old_config} -n ${kube_ns} get sa ${kube_sa_name} -o jsonpath={.secrets[0].name})
    # 获得 token
    sa_token=$(${kube_cmd} --kubeconfig ${kube_old_config} -n ${kube_ns} get secret ${sa_secret} -o jsonpath={.data.token} | base64 -d)
    
    echo_yellow "${kube_cmd} config set-credentials ${kube_sa_name} --token=${sa_token} \
    --kubeconfig=${kube_new_config}"
    # 为kubeconfig中设置 token 
    ${kube_cmd} config set-credentials "${kube_sa_name}" --token=${sa_token} \
    --kubeconfig=${kube_new_config}
    # 设置 context
    echo_yellow "${kube_cmd} config set-context ${kube_sa_name} --cluster=${kube_cluster_name} \
    --user=${kube_sa_name} --kubeconfig=${kube_new_config}"
    
    ${kube_cmd} config set-context ${kube_sa_name} --cluster=${kube_cluster_name} \
    --user=${kube_sa_name} --kubeconfig=${kube_new_config}

    # 使用指定的context
    echo_yellow "${kube_cmd} config use-context ${kube_sa_name} --kubeconfig=${kube_new_config}"
    ${kube_cmd} config use-context ${kube_sa_name} --kubeconfig=${kube_new_config}
}

# 为新的kubeconfig设置用户的证书
kubeconfig_set_user_cert(){
    local rolebinding_info=""
    create_cert 
    cd ${cert_dir}
    echo_yellow "$kube_cmd --kubeconfig ${kube_old_config} -n ${kube_ns} get ${role_type} ${kube_rb_name}"
    # rolebinding 资源的检测
    rolebinding_info=$($kube_cmd --kubeconfig ${kube_old_config} -n ${kube_ns} get ${role_type} ${kube_rb_name} || /bin/true)
    #get_rb_ret=$?
    #if [ ${get_rb_ret} == 0 ];then
    if [ -n "${rolebinding_info}" ];then
        :
    else
        echo_yellow "$kube_cmd --kubeconfig ${kube_old_config} -n ${kube_ns} create ${role_type} ${kube_rb_name} --clusterrole=${kube_cluster_role} --user=${kube_user_name}"
        # 执行创建操作
        $kube_cmd --kubeconfig ${kube_old_config} -n ${kube_ns} create ${role_type} ${kube_rb_name} --clusterrole=${kube_cluster_role} --user=${kube_user_name}
    fi
    # 为 kubeconfig 设置用户的证书和 key
    $kube_cmd config set-credentials ${kube_user_name} --embed-certs=true \
      --client-certificate=${kube_user_name}.crt \
      --client-key=${kube_user_name}.key \
      --kubeconfig ${kube_new_config}
    # 设置 context
    ${kube_cmd} config set-context ${kube_user_name}@${kube_cluster_name} --cluster=${kube_cluster_name} \
      --user=${kube_user_name} --kubeconfig=${kube_new_config}
    # 使用context
    ${kube_cmd} config use-context ${kube_user_name}@${kube_cluster_name} --kubeconfig=${kube_new_config}
}
# 创建完成后的汇总信息
summary_info(){
    echo ""
    echo "Created summary."
    if [ -n "${kube_sa_name}" ];then
        echo_green "    Created a sa ${kube_sa_name} in namespace ${kube_ns}."
    fi
    if [ -n "${kube_user_name}" ];then
        echo_green "    Created user's certificate in ${cert_dir}."
    fi
    echo_green "    Created a ${role_type} ${kube_rb_name} in ${kube_ns}."
    echo_green "    Created a new kubeconfig ${kube_new_config}."
}

main(){
    echo_yellow 'call the kubeconfig_set_root_ca function.'
    kubeconfig_set_root_ca
    if [ -n "${kube_sa_name}" ];then
        echo_yellow 'call the kubeconfig_set_sa_token function.'
        kubeconfig_set_sa_token
    fi
    if [ -n "${kube_user_name}" ];then
        echo_yellow 'call the kubeconfig_set_user_cert function.'
        kubeconfig_set_user_cert
    fi
    summary_info
}
# 基本写完，创建操作没有进行完整的测试
main
