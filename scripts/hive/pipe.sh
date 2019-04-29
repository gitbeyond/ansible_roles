#!/bin/bash
tail -f export_done.txt | while read line;do
    ssh 172.16.12.16 "echo '$line' >> /home/hdfs/hive_table/export_done.txt"
done
