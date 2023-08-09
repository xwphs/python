#!/bin/bash

#使用方法：
#1、输入命令crontab -e打开cron编辑器
#2、在最后一行追加0 5 * * * /bin/sh /delete_logs_file_path/delete_logs
#3、保存退出

#路径需要已经存在
LOGS_PATH=/youdata/logs
LOGS_KEEP_DAYS=14

find $LOGS_PATH -mtime +$LOGS_KEEP_DAYS -type f -delete
docker system prune -f
