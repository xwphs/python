#!/bin/bash

# 通用 MySQL 备份脚本, 主要用于 phmgr 备份
# $1 ip
# $2 port
# $3 username  (default: youdata_admin)
# $4 password  (default: youdata_admin)
# $5 bin_path (default: /youdata_phmgr/client/bin/mysql*/bin/mysqldump)
#
# 使用方法：
# 1、输入命令 crontab -e 打开 cron 编辑器
# 2、在最后一行追加 0 2 * * * /bin/sh /youdata/scripts/backup_common.sh {ip} {port}
# 3、保存退出

BACKUP_PATH="/youdata/db_data_bak"
LOG="${BACKUP_PATH}/backup.log"
DATE_POSTFIX=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="${BACKUP_PATH}/backup-${DATE_POSTFIX}.sql"
BACKUP_COMPLEX_FILE="${BACKUP_PATH}/backup-complex-${DATE_POSTFIX}.sql"
BACKUP_AAC_FILE="${BACKUP_PATH}/backup-aac-${DATE_POSTFIX}.sql"
mkdir -p ${BACKUP_PATH}
echo "[${DATE_POSTFIX}] Start to backup mysql data." >>$LOG

ip=$1
port=$2
if [[ -z "$ip" ]]; then
    echo "ERROR! ip does not exist!" >>$LOG
    exit 1
fi
if [[ -z "$port" ]]; then
    echo "ERROR! port does not exist!" >>$LOG
    exit 1
fi
[[ -z "$3" ]] && username="youdata_admin" || username=$3
[[ -z "$4" ]] && password="youdata_admin" || password=$4
[[ -z "$5" ]] && bin_path="/youdata_phmgr/client/bin/mysql-5.7.20-v3e-linux-x86_64/bin" || bin_path=$5
echo "IP: $ip, PORT: $port, USERNAME: $username, PASSWORD: $password, BIN_PATH: $bin_path" >>$LOG

## 备份 youdata 库
SECONDS=0
${bin_path}/mysqldump -h $ip -P $port --user=$username --password=$password --default-character-set=utf8mb4 --single-transaction --set-gtid-purged=OFF youdata >$BACKUP_FILE 2>>$LOG
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

## 备份 mis2datasource 库

temp_query=$("${bin_path}"/mysql -h $ip -P $port -u$username -p$password -e "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'mis2datasource';" 2>>$LOG)
if [ ! -z "$temp_query" ]; then
  SECONDS=0
  ${bin_path}/mysqldump -h $ip -P $port --user=$username --password=$password --default-character-set=utf8mb4 --single-transaction --set-gtid-purged=OFF mis2datasource >$BACKUP_COMPLEX_FILE 2>>$LOG
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
#
## 备份 AAC auth_system 库
temp_query=$("${bin_path}"/mysql -h $ip -P $port -u$username -p$password -e "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'auth_system';" 2>>$LOG)
if [ ! -z "$temp_query" ]; then
  SECONDS=0
  ${bin_path}/mysqldump -h $ip -P $port --user=$username --password=$password --default-character-set=utf8mb4 --single-transaction --set-gtid-purged=OFF auth_system >$BACKUP_AAC_FILE 2>>$LOG
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

##删除5天前的备份
find ${BACKUP_PATH} -mtime +5 -type f -delete

exit $ret
