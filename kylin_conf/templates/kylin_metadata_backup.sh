#!/bin/bash
export PATH={{ ansible_env["PATH"] }}

KYLIN_HOME={{kylin_base_dir}}
backup_script=${KYLIN_HOME}/bin/metastore.sh
mail_script={{script_deploy_dir}}/send_mail.py
project_name="hdp7 172.16.7.40 kylin_metadata"
backup_dir={{kylin_data_dir}}/meta_backups


[ -d ${backup_dir} ] || mkdir -p ${backup_dir}
echo "`date` begin backup kylin metadata."
${backup_script} backup &> /dev/null
backup_stat=$?

cd ${backup_dir}
if [ ${backup_stat} == 0 ];then
    new_backup_file=$(ls ${backup_dir}/ |tail -n 1)
    backup_file_size=$(du -sh ${new_backup_file})
    echo "`date` kylin metadata backup successful!"
    mail_text="`date` ${project_name} backup successed.
file size is: ${backup_file_size}"
else
    echo "`date` kylin metadata backup failed."
    mail_text="`date` ${project_name} backup failed."
fi

python ${mail_script} "${project_name}" "${mail_text}"
