
#!/bin/bash

images=(
apptomcat
apptomcatmaster
apptomcatslave
apptomcatsmscb
apptomcatloanclue
apptomcatloanflow
geo-provider-auth
geo-consumer-auth
auth-dubbo-admin
)

for img in ${images[@]};do
    img_tag=($(docker images |awk "/${img}\>/{print \$1\":\"\$2}"))
    img_tag_md5=($(docker images |awk "/${img}\>/{print \$3}"))
    echo ${img_tag[@]}
    #echo ${img_tag_md5[@]}
    docker rmi ${img_tag_md5[@]}
done

