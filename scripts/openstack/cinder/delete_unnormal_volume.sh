
source /opt/stack_client/bin/activate
source /root/sch_openrc.sh

old_volumes=(
#d2aeaf45-e180-4240-aae2-04e9e1935281
a26401a9-3ab0-49dd-80cc-afb83c6b94c0
6516488a-4abd-4ca7-b7cd-6e8f623d314a
1c4b408d-1421-4b78-9999-b8f417f94c71
)

curl_cmd=/opt/.bakcurl

get_volume_call_url(){
# (stack_client) [root@cent7-4 ~]# cinder --debug show d2aeaf45-e180-4240-aae2-04e9e1935281 2>&1 |grep  "DEBUG:keystoneauth:REQ"
#DEBUG:keystoneauth:REQ: curl -g -i -X GET http://10.111.32.234:8776/v3/f0e18acc83ed4085841ae650e77e7d72/volumes/d2aeaf45-e180-4240-aae2-04e9e1935281 -H "User-Agent: python-cinderclient" -H "Accept: application/json" -H "X-Auth-Token: {SHA1}1947bb20404c2aea707b91b983269c3f39c1532d"
    local volume_id=$1
    cinder --debug show ${volume_id} 2>&1 |grep  "DEBUG:keystoneauth:REQ" |awk '{print $7}'
}

get_openstack_token(){
#(stack_client) [root@cent7-4 script]# openstack token issue |grep "\<id\>" |awk '{print $4}'
#gAAAAABfFQPnIdEjLvD9lXsnW2bMM-GSqVvGbRwQog1fdRlC1-th_syxz7JSVMBxOxnrWLFIrrFd-Oj2CdLmx68R-t-fC2Xi0B5NdGNSi3JGvYkuDZDfkQ31To72Gsk8Zwahd1nkEbRb86d1Q4CwcWFb4_aAS-oxU1ZMYpaI1rYiSA7nB3U-UEo
    openstack token issue |grep "\<id\>" |awk '{print $4}'    
}

get_volume_attach_id(){
    local volume_id=$1
    #mysql -Bse "select * from cinder.volume_attachment where volume_id='${volume_id}';"
    mysql -Bse "select id from cinder.volume_attachment where volume_id='${volume_id}';"
}

for volume in ${old_volumes[@]};do
    volume_attach_id=$(get_volume_attach_id ${volume})
    volume_call_url=$(get_volume_call_url ${volume})
    ops_token=$(get_openstack_token)
    #volume_call_url="${curl_cmd} -g -i -X POST ${volume_call_url}/action -H 'User-Agent: python-cinderclient' -H 'Content-Type: application/json' -H 'X-Auth-Token: ${ops_token}' -d '{\"os-detach\": {\"attachment_id\": \"${volume_attach_id}\"}}'"
    echo ${volume_call_url}
    #${volume_call_url}
    ${curl_cmd} -g -i -X POST ${volume_call_url}/action -H 'User-Agent: python-cinderclient' -H 'Content-Type: application/json' -H 'Accept: application/json' -H 'X-Auth-Token: '${ops_token}'' -d '{"os-detach": {"attachment_id": "'${volume_attach_id}'"}}'
    openstack volume delete ${volume}
done


#/opt/.bakcurl -g -i -X POST http://10.111.32.234:8776/v3/f0e18acc83ed4085841ae650e77e7d72/volumes/2d3ed394-4942-4ae0-b405-a75616343a08/action -H "User-Agent: python-cinderclient" -H "Content-Type: application/json" -H "Accept: application/json" -H "X-Auth-Token: gAAAAABfFP4iL1jx5KCU0mNZZXHq9yvWY1TNM52h18QKjiGvBXl-IvnPc_zUcEzv3nQkleLXI81d-stnwPvy8SxNwDwB5nAZlvhzdqPajY7bheQTv70fRf6F_B-23O5c9bkjbV__OhkoTcpxu4uvOxdFBfCLDF04VV-BVLK46sPOpoyv9rsuLQw" -d '{"os-detach": {"attachment_id": "cd2b3db5-2848-417b-971b-b7a881319016"}}'
