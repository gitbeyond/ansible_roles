export JENKINS_USER_ID=wanghaifeng
export JENKINS_API_TOKEN=1c5e81ed546c156ac104c0c8f12b39d6
#export JENKINS_API_TOKEN=117b26b09abe418c0e4b7fe23e48787607
#export JENKINS_URL=http://jenkins-corp.geotmt.com/
export JENKINS_URL=http://jenkins-corp.geotmt.com:8080/
jenkins_jar_file=/data/apps/soft/ansible/jenkins/2.150.1/jenkins-cli.jar

#WebSocket connection mode
#In Jenkins 2.217 and above, the -webSocket mode may be used as an alternative to -http. The advantage is that a more standard transport is used, avoiding problems with many reverse proxies or the need for special proxy configuration.

# webSocket 在 2.217 的版本以上才支持,而且需要注意反向代理的问题，如果nginx代理jenkins,nginx 没有配置 websocket,那么不能使用

java -jar ${jenkins_jar_file} -http who-am-i
