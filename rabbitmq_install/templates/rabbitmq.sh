export RABBITMQ_HOME={{rabbitmq_base_dir}} 
export PATH=${RABBITMQ_HOME}/sbin:$PATH

export RABBITMQ_CONFIG_FILE={{rabbitmq_conf_dir}}/rabbitmq.conf

# overrides advanced config file location
export RABBITMQ_ADVANCED_CONFIG_FILE={{rabbitmq_conf_dir}}/advanced.config

# overrides environment variable file location
export RABBITMQ_CONF_ENV_FILE={{rabbitmq_conf_dir}}/rabbitmq-env.conf
