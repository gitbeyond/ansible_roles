#!/bin/bash

project_base_dir=${project_base_dir:-/usr/local/bin}
project_name=${HOSTNAME%-*}
project_name=${project_name%-*}
project_jar_file=$(ls ${project_base_dir}/${project_name}*.jar)

if [ -n "${project_jar_file}" ];then
    if [ -e "${project_jar_file}" ];then
        :
    else
        echo "The jar_file:${project_jar_file} isn't exist."
        exit 3
    fi
else
    echo "There isn't a jar file in the ${project_base_dir}."
    exit 2
fi

if [ -n "${JAVA_OPTS}" ];then
    :
else
    if [ -n "${CATALINA_OPTS}" ];then
        JAVA_OPTS="${CATALINA_OPTS}"
    fi
fi

echo "java ${JAVA_OPTS} -jar ${project_jar_file} ${project_run_opts}"
exec java ${JAVA_OPTS} -jar ${project_jar_file} ${project_run_opts}
