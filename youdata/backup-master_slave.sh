#!/bin/bash

# 双机 mysql 备份脚本（只适用于 lts-5.6 之前版本）
# 使用方法：
# 1、输入命令 crontab -e 打开 cron 编辑器
# 2、在最后一行追加 0 2 * * * /bin/sh /backup_file_path/backup_master_slave.sh
# 3、保存退出

BACKUP_PATH="/youdata/db_data_bak"
mkdir -p ${BACKUP_PATH}

DATE_POSTFIX=`date +"%Y-%m-%d_%H-%M-%S"`

docker exec $(docker ps | grep hamysql | cut -f 1 -d ' ') mysqldump --single-transaction --set-gtid-purged=OFF --master-data=2 youdata > ${BACKUP_PATH}/backup-${DATE_POSTFIX}.sql

#删除5天前的备份
find ${BACKUP_PATH} -mtime +5 -type f -delete
