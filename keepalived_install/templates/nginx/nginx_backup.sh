#!/bin/bash
export PATH={{ansible_env.PATH}}


dt=$(date +%Y%m%d%H%M%S)

keep_state="Backup"
base_dir=$(cd "$(dirname "${0}")"; pwd)

echo "${dt} [${keep_state}]" >> ${logfile}
