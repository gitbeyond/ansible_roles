#!/bin/bash

jenkins_war=/data/apps/opt/jenkins/jenkins-2.382.war
export JENKINS_HOME=/data/apps/data/jenkins
export JENKINS_PORT="8091"
#JAVA_OPTS="-Xms4096m -Xmx4096m"
JAVA_OPTS=""
# jenkins_opts="--httpPort=${JENKINS_PORT} --webroot ${JENKINS_HOME}/war --pluginroot ${JENKINS_HOME}/plugins"
jenkins_opts="--httpPort=${JENKINS_PORT}"
exec java ${JAVA_OPTS} -jar ${jenkins_war} ${jenkins_opts}
