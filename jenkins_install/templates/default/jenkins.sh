#!/bin/bash
# editor: haifengsss@163.com
set -euo pipefail
jenkins_war="{{jenkins_install_dir}}/{{jenkins_war_file_link_name}}"
export JENKINS_HOME="{{jenkins_data_dir}}"
export JENKINS_PORT="{{jenkins_run_port}}"
JAVA_OPTS="{{jenkins_java_opts}}"
jenkins_opts="{{jenkins_run_opts}}"
# --logfile=/var/log/jenkins/jenkins.log
# --webroot=/var/cache/jenkins/war 
# --daemon 
# --debug=5 --handlerCountMax=100 --handlerCountMaxIdle=20 
# https://www.jenkins.io/doc/book/installing/initial-settings/#networking-parameters
# java -jar  /data/apps/opt/jenkins/jenkins.war --help
# jenkins_opts="--webroot=${JENKINS_HOME}/war --pluginroot=${JENKINS_HOME}/plugins"
exec java ${JAVA_OPTS} -jar ${jenkins_war} ${jenkins_opts}
