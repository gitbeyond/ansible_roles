#!/bin/bash
 
#Get InnoDB Row Lock Details and InnoDB Transcation Lock Memory
#mysql> SELECT SUM(trx_rows_locked) AS rows_locked, SUM(trx_rows_modified) AS rows_modified, SUM(trx_lock_memory_bytes) AS lock_memory FROM information_schema.INNODB_TRX;
#+-------------+---------------+-------------+
#| rows_locked | rows_modified | lock_memory |
#+-------------+---------------+-------------+
#|        NULL |          NULL |        NULL |
#+-------------+---------------+-------------+
#1 row in set (0.00 sec)
 
#+-------------+---------------+-------------+
#| rows_locked | rows_modified | lock_memory |
#+-------------+---------------+-------------+
#|           0 |             0 |         376 |
#+-------------+---------------+-------------+
 
#Get InnoDB Compression Time
#mysql> SELECT SUM(compress_time) AS compress_time, SUM(uncompress_time) AS uncompress_time FROM information_schema.INNODB_CMP;
#+---------------+-----------------+
#| compress_time | uncompress_time |
#+---------------+-----------------+
#|             0 |               0 |
#+---------------+-----------------+
#1 row in set (0.00 sec)
 
 
#Get InnoDB Transaction states
 
#TRX_STATE  Transaction execution state. One of RUNNING, LOCK WAIT, ROLLING BACK or COMMITTING.
 
#mysql> SELECT LOWER(REPLACE(trx_state, " ", "_")) AS state, count(*) AS cnt from information_schema.INNODB_TRX GROUP BY state;
#+---------+-----+
#| state   | cnt |
#+---------+-----+
#| running |   1 |
#+---------+-----+
#1 row in set (0.00 sec)
 
#export PATH=/usr/local/mysql/bin/:/usr/lib64/qt-3.3/bin:/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/root/bin
export PATH={{ansible_env.PATH}}
 
conf_file={{zabbix_dir}}/etc/.my.cnf
CMD="{{mysql_basedir}}/bin/mysql --defaults-file=${conf_file} -N"

dataDir={{mysql_datadir}}
pid=$(ps aux |grep "${dataDir}" |awk '/^mysql/{print $2}')
innodb_stat_file="${dataDir}/innodb_status.${pid}"
#echo ${innodb_stat_file}

innodb_metric=$1
 
case $innodb_metric in
   Innodb_rows_locked)
       value=$(echo "SELECT SUM(trx_rows_locked) AS rows_locked FROM information_schema.INNODB_TRX;"| ${CMD} | awk '{print $1}')
       if [ "$value" == "NULL" ];then
          echo 0
       else
          echo $value
       fi
   ;;
   Innodb_rows_modified)
       value=$(echo "SELECT SUM(trx_rows_modified) AS rows_modified FROM information_schema.INNODB_TRX;"|${CMD}| awk '{print $1}')
       if [ "$value" == "NULL" ];then
          echo 0
       else
          echo $value
       fi
   ;;
   Innodb_trx_lock_memory)
       value=$(echo "SELECT SUM(trx_lock_memory_bytes) AS lock_memory FROM information_schema.INNODB_TRX;"|${CMD}| awk '{print $1}')
       if [ "$value" == "NULL" ];then
          echo 0
       else
          echo $value
       fi
       ;;
    Innodb_compress_time)
        value=$(echo "SELECT SUM(compress_time) AS compress_time, SUM(uncompress_time) AS uncompress_time FROM information_schema.INNODB_CMP;"|${CMD}|awk '{print $1}')
        echo $value
   ;;
   Innodb_uncompress_time)
       value=$(echo "SELECT SUM(compress_time) AS compress_time, SUM(uncompress_time) AS uncompress_time FROM information_schema.INNODB_CMP;"|${CMD}|awk '{print $2}')
       echo $value
   ;;   
   Innodb_trx_running)
       value=$(echo 'SELECT LOWER(REPLACE(trx_state, " ", "_")) AS state, count(*) AS cnt from information_schema.INNODB_TRX GROUP BY state;'|${CMD}|grep running|awk '{print $2}')
       if [ "$value" == "" ];then
          echo 0
       else
          echo $value
       fi
       ;;
   Innodb_trx_lock_wait)
       value=$(echo 'SELECT LOWER(REPLACE(trx_state, " ", "_")) AS state, count(*) AS cnt from information_schema.INNODB_TRX GROUP BY state;'|${CMD}|grep lock_wait|awk '{print $2}')
       if [ "$value" == "" ];then
          echo 0
       else
          echo $value
       fi
       ;;
    Innodb_trx_rolling_back)
        value=$(echo 'SELECT LOWER(REPLACE(trx_state, " ", "_")) AS state, count(*) AS cnt from information_schema.INNODB_TRX GROUP BY state;'|${CMD}|grep rolling_back|awk '{print $2}')
        if [ "$value" == "" ];then
           echo 0
        else
           echo $value
        fi
        ;;
    Innodb_trx_committing)
        value=$(echo 'SELECT LOWER(REPLACE(trx_state, " ", "_")) AS state, count(*) AS cnt from information_schema.INNODB_TRX GROUP BY state;'|${CMD}|grep committing|awk '{print $2}')
        if [ "$value" == "" ];then
           echo 0
        else
           echo $value
        fi
        ;;
    Innodb_trx_history_list_length)
        cat ${innodb_stat_file} |grep "History list length"|awk '{print $4}'
        ;;
    Innodb_last_checkpoint_at)
        cat ${innodb_stat_file} |grep "Last checkpoint at"|awk '{print $4}'
        ;;
    Innodb_log_sequence_number)
        cat ${innodb_stat_file} |grep "Log sequence number"|awk '{print $4}'
        ;;
    Innodb_log_flushed_up_to)
        cat ${innodb_stat_file} |grep "Log flushed up to"|awk '{print $5}'
        ;;
    Innodb_open_read_views_inside_innodb)
        cat ${innodb_stat_file} |grep "read views open inside InnoDB"|awk '{print $1}'
        ;;
    Innodb_queries_inside_innodb)
        cat ${innodb_stat_file} |grep "queries inside InnoDB"|awk '{print $1}'
        ;;
    Innodb_queries_in_queue)
        cat ${innodb_stat_file} |grep "queries in queue"|awk '{print $5}'
        ;;
    Innodb_hash_seaches)
        cat ${innodb_stat_file} |grep "hash searches"|awk '{print $1}'
        ;;
    Innodb_non_hash_searches)
        cat ${innodb_stat_file} |grep "non-hash searches/s"|awk '{print $4}'
        ;;
    Innodb_node_heap_buffers)
         #cat ${innodb_stat_file} |grep "node heap"| awk '{print $8}'
         cat ${innodb_stat_file} |grep "node heap"| awk '{a+=$8}END{print a}'
        ;;
    Innodb_RW_shared_spins)
        cat ${innodb_stat_file}  | grep "RW-shared spins" | awk '{print $3}' |awk -F, '{print $1}'
    ;;
    Innodb_RW_shared_rounds)
        cat ${innodb_stat_file}  | grep "RW-shared spins" | awk '{print $5}' |awk -F, '{print $1}'
    ;;
    Innodb_RW_shared_OSwaits)
        cat ${innodb_stat_file}  | grep "RW-shared spins" | awk '{print $8}'
    ;;
    Innodb_RW_excl_spins)
        cat ${innodb_stat_file}  | grep "RW-excl spins" | awk '{print $3}' |awk -F, '{print $1}'
    ;;
    Innodb_RW_excl_rounds)
        cat ${innodb_stat_file}  | grep "RW-excl spins" | awk '{print $5}' |awk -F, '{print $1}'
    ;;
    Innodb_RW_excl_OSwaits)
        cat ${innodb_stat_file}  | grep "RW-excl spins" | awk '{print $8}'
    ;;
#    Innodb_Mutex_spins)
#        cat ${innodb_stat_file}  | grep "Mutex spin" | awk '{print $4}' |awk -F, '{print $1}'
#    ;;
#    Innodb_Mutex_rounds)
#        cat ${innodb_stat_file}  | grep "Mutex spin" | awk '{print $6}' |awk -F, '{print $1}'
#    ;;
#    Innodb_Mutex_OSwaits)
#        cat ${innodb_stat_file}  | grep "Mutex spin" | awk '{print $9}'
#    ;;
     Innodb_mutex_os_waits)
         cat ${innodb_stat_file} |grep "Mutex spin waits"|awk '{print $9}'
         ;;
     Innodb_mutex_spin_rounds)
         cat ${innodb_stat_file} |grep "Mutex spin waits"|awk '{print $6}'|tr -d ','
         ;;
     Innodb_mutex_spin_waits)
         cat ${innodb_stat_file} |grep "Mutex spin waits"|awk '{print $4}'|tr -d ','
         ;; 
 
    *)
        echo "wrong parameter"
    ;;
 
esac
