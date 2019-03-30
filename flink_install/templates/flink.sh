HDP_VERSION=$(hdp-select versions)
export HADOOP_COMMON_HOME="/usr/hdp/${HDP_VERSION}/hadoop"
export HADOOP_CONF_DIR="/usr/hdp/${HDP_VERSION}/hadoop/conf"
export YARN_CONF_DIR="/usr/hdp/${HDP_VERSION}/hadoop/conf"
export HADOOP_YARN_HOME="/usr/hdp/${HDP_VERSION}/hadoop-yarn"

export HADOOP_CLASSPATH=$(hadoop classpath)
export FLINK_HOME={{flink_base_dir}}
export PATH=${FLINK_HOME}/bin:$PATH
