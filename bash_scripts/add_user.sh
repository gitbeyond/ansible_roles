#!/bin/bash
export PATH=/usr/lib64/qt-3.3/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
#max_uid=$(ldapsearch -x -LLL  |grep -i uidnumber |awk '{print $2}' | sort -n |tail -n 1)
basedc="dc=geotmt,dc=com"
max_uid=$(ldapsearch -x -LLL -b"${basedc}" 'uidNumber'  |grep -i uidnumber |awk '{print $2}' | sort -n |tail -n 1)
add_uid=$[max_uid+1]

username=${1}
displayname=${2}
groupname=${3}
user_shell=${4:-/bin/bash}

admin_user="cn=geoadmin,${basedc}"
admin_pass='ge()_R()()t'
group_script=/root/openldap/hive_user/add_group.sh
ldif_dir=./ldif

usage(){
    echo "$0 username displayname groupname [user_shell:-/bin/bash]"
}
if [ $# -lt 3 ];then
    usage
    exit 5
fi
# 如果 ${username} 已经存在于 openldap 服务器中，脚本中止
if ldapsearch -x -LLL -b"ou=People,${basedc}" "uid=${username}" |grep "${username}" &> /dev/null;then
    echo "the ${username} already exist."
    exit 6
fi

# 如果 ${groupname} 不为空的话
# 那么查询尝试查询这个 ${groupname} 的gidNumber
if [ -n "${groupname}" ];then
    # 获取 ${groupname} 的gidNumber
    add_gid=$(ldapsearch -x -LLL -b"ou=Group,${basedc}" "cn=${groupname}" 'gidNumber' |awk '/gidNumber/{print $NF}')
    # 如果 ${add_gid} 不为空的话,那么即确定了 ${add_gid} 的值
    if [ -n "${add_gid}" ];then
        #sed -i "s/gidNumber: \(.*\)/gidNumber: ${add_gid}/" ${username}.ldif
        :
    else
        # add_gid 为空，未能通过传递来的 groupname 得到正确的 gidNumber,现在添加这个组
        # 执行添加组的操作
        add_gid=$(/bin/bash ${group_script})
        # 添加成功会返回 0 状态码
        if [ $? == 0 ];then
            #sed -i "s/gidNumber: \(.*\)/gidNumber: ${add_gid}/" ${username}.ldif
            :
        else
            echo "add group ${groupname} failed."
            exit 7
        fi
    fi
else
    # groupname 为空
    usage
    exit 8
fi
ldif_template="\
dn: uid=${username},ou=People,${basedc}
uid: ${username}
cn: ${username}
objectClass: person
objectClass: posixAccount
objectClass: inetOrgPerson
objectClass: shadowAccount
objectClass: hostObject
sn: ${username}
displayName: ${displayname}
userPassword: {CRYPT}cr2uYqMuwg40o
shadowLastChange: 16903
loginShell: ${user_shell}
uidNumber: ${add_uid}
gidNumber: ${add_gid}
homeDirectory: /home/${username}
mail: ${username}@geotmt.com"

cat << EOF > ${ldif_dir}/${username}_user.ldif
${ldif_template}
EOF

# 执行添加用户
ldapadd -x -D "${admin_user}" -w "${admin_pass}" -f ${ldif_dir}/${username}.ldif

# 添加 group 的 memberUid 属性
cat << EOF | ldapmodify -D "${admin_user}" -w "${admin_pass}"
dn: cn=${groupname},ou=Group,${basedc}
changetype: modify
add: memberUid
memberUid: ${username}
EOF
