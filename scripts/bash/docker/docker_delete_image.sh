#!/bin/bash

docker_registry_addr=http://172.16.9.91
docker_registry_user=admin
docker_registry_pass=Harbor12345

curl_opt="-u${docker_registry_user}:${docker_registry_pass}"
curl_cmd=/usr/bin/curl
get_library(){
    local project=$1
    ${curl_cmd} ${curl_opt} --header 'Accept: application/json' "${docker_registry_addr}/api/search?q=${project}"   
}

get_library antifraud

get_tags(){
    local repo=$1
    repo=${repo//\//%2F}
    ${curl_cmd} ${curl_opt} --header 'Accept: application/json' "${docker_registry_addr}/api/repositories/${repo}/tags"   
}

get_tags antifraud/geo/tomcat
