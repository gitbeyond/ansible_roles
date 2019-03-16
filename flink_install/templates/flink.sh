HDP_VERSION={{hdp_version.stdout}}
export HADOOP_COMMON_HOME='/usr/hdp/{{hdp_version.stdout}}/hadoop'
export HADOOP_CONF_DIR='/usr/hdp/{{hdp_version.stdout}}/hadoop/conf'
export YARN_CONF_DIR='/usr/hdp/{{hdp_version.stdout}}/hadoop/conf'
export HADOOP_YARN_HOME='/usr/hdp/{{hdp_version.stdout}}/hadoop-yarn'

export HADOOP_CLASSPATH=`hadoop classpath`

export FLINK_HOME={{flink_base_dir}}
export PATH=${FLINK_HOME}/bin:$PATH
