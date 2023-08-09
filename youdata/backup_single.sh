#!/bin/bash

# 单机 MySQL 备份脚本
# 使用方法：
# 1、输入命令 crontab -e 打开 cron 编辑器
# 2、在最后一行追加 0 2 * * * /bin/sh /backup_file_path/backup_single.sh
# 3、保存退出

BACKUP_PATH="/youdata/db_data_bak"
LOG="${BACKUP_PATH}/backup.log"
DATE_POSTFIX=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="${BACKUP_PATH}/backup-${DATE_POSTFIX}.sql"
BACKUP_COMPLEX_FILE="${BACKUP_PATH}/backup-complex-${DATE_POSTFIX}.sql"
BACKUP_AAC_FILE="${BACKUP_PATH}/backup-aac-${DATE_POSTFIX}.sql"

mkdir -p ${BACKUP_PATH}

echo "[${DATE_POSTFIX}] Start to backup mysql data." >>$LOG

# 从 yaml 中读取 mysql 密码
version=$(docker ps | grep "web:lts-" | head -n 1 | awk -F ' ' {'print $2'} | cut -f 2 -d "-")
version_no_point=${version/./}
yaml="/youdata/installer/docker-stack.youdata${version_no_point}.yaml"

if [ ! -f $yaml ]; then
    echo "ERROR! $yaml does NOT exist!" >>$LOG
    exit 1
fi

db=$(cat $yaml | grep DB | head -n 1)
db_password=$(echo $db | rev | cut -f 2- -d @ | rev | cut -f 4- -d :)
# echo "DB password: $db_password"

mysql_cid=$(docker ps | grep "mysql:stable" | cut -f 1 -d ' ')
if [ -z $mysql_cid ]; then
    # 兼容 stable tag 之间的版本
    mysql_cid=$(docker ps | grep "mysql" | grep -v "exporter" | cut -f 1 -d ' ')
fi

IFS=' ' read -d "" -ra cid_arr <<<$mysql_cid
if [ ${#cid_arr[@]} -gt 1 ]; then
    echo "ERROR! Get multiple MySQL container ids." >>$LOG
    exit 1
fi

if [ -z $mysql_cid ]; then
    echo "ERROR! Can NOT get MySQL container id, please check MySQL is running." >>$LOG
    exit 1
fi

# 备份 youdata 库
SECONDS=0
docker exec $mysql_cid mysqldump --user="youdata" --password=$db_password --default-character-set=utf8mb4 --single-transaction --set-gtid-purged=OFF youdata >$BACKUP_FILE 2>>$LOG
ret=$?
duration=$SECONDS
if [ $ret == "0" ]; then
    echo "Backup db youdata success. It takes $duration seconds." >>$LOG
    sql_size=$(du -m $BACKUP_FILE | cut -f1)
    echo "Backup db youdata SQL: ${BACKUP_FILE}: $sql_size MB." >>$LOG
else
    echo "Backup db youdata failed. It takes $duration seconds." >>$LOG
    sql_size=$(du -m $BACKUP_FILE | cut -f1)
    echo "Backup db youdata SQL: ${BACKUP_FILE}: $sql_size MB." >>$LOG
fi

# 备份 mis2datasource 库
temp_query=$(docker exec $mysql_cid mysql -uyoudata -p$db_password -e "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'mis2datasource';" 2>>$LOG)
if [ ! -z "$temp_query" ]; then
  SECONDS=0
  docker exec $mysql_cid mysqldump --user="youdata" --password=$db_password --default-character-set=utf8mb4 --single-transaction --set-gtid-purged=OFF mis2datasource >$BACKUP_COMPLEX_FILE 2>>$LOG
  ret=$?
  duration=$SECONDS
  if [ $ret == "0" ]; then
      echo "Backup db mis2datasource success. It takes $duration seconds." >>$LOG
      sql_size=$(du -m $BACKUP_COMPLEX_FILE | cut -f1)
      echo "Backup db mis2datasource SQL: ${BACKUP_COMPLEX_FILE}: $sql_size MB." >>$LOG
  else
      echo "Backup db mis2datasource failed. It takes $duration seconds." >>$LOG
      sql_size=$(du -m $BACKUP_COMPLEX_FILE | cut -f1)
      echo "Backup db mis2datasource SQL: ${BACKUP_COMPLEX_FILE}: $sql_size MB." >>$LOG
  fi
else
   echo "db mis2datasource does not exist, skip. " >>$LOG
fi

# 备份 AAC auth_system 库
temp_query=$(docker exec $mysql_cid mysql -uyoudata -p$db_password -e "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'auth_system';" 2>>$LOG)
if [ ! -z "$temp_query" ]; then
  SECONDS=0
  docker exec $mysql_cid mysqldump --user="youdata" --password=$db_password --default-character-set=utf8mb4 --single-transaction --set-gtid-purged=OFF auth_system >$BACKUP_AAC_FILE 2>>$LOG
  ret=$?
  duration=$SECONDS
  if [ $ret == "0" ]; then
      echo "Backup db auth_system success. It takes $duration seconds." >>$LOG
      sql_size=$(du -m $BACKUP_AAC_FILE | cut -f1)
      echo "Backup db auth_system SQL: ${BACKUP_AAC_FILE}: $sql_size MB." >>$LOG
  else
      echo "Backup db auth_system failed. It takes $duration seconds." >>$LOG
      sql_size=$(du -m $BACKUP_AAC_FILE | cut -f1)
      echo "Backup db auth_system SQL: ${BACKUP_AAC_FILE}: $sql_size MB." >>$LOG
  fi
else
   echo "db auth_system does not exist, skip. " >>$LOG
fi

#删除5天前的备份
find ${BACKUP_PATH} -mtime +5 -type f -delete

exit $ret
