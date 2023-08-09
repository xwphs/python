#!/bin/bash

#使用方法
#1. 输入命令crontab -e 打开cron编辑器
#2. 在最后一行追加 * * * * * /bin/sh /monitor_dockerd_file_path/monitor_dockerd.sh
#3. 保存退出

step=5 #间隔的秒数

for (( i = 0; i < 60; i=(i+step) )); do
	STATUS=`systemctl is-failed docker` 
        if [ $STATUS == "active" ]; then
           sleep $step
        else
           systemctl status docker >> /youdata/logs/dockerd/docker.log
           echo "===================================================" >> /youdata/logs/dockerd/docker.log
           systemctl start docker
        fi
done

exit 0
