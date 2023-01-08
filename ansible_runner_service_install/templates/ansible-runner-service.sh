#!/bin/bash
set -a
runner_service_var_file='{{runner_service_var_dir}}/ansible-runner-service_env.sh'
gunicorn_conf_file='{{runner_service_conf_dir}}/gunicorn.py'
source ${runner_service_var_file}

PATH={{ansible_venv}}/bin:$PATH

exec gunicorn -c ${gunicorn_conf_file} wsgi:application
