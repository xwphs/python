#!/usr/bin/env bash
#
# 该脚本用于升级到 lts-4.7 版本中的 store 文件迁移
#
# usage: bash store_migrate.sh ydswarm
#

folder=$1
if [ ! -z $folder ]; then
  for i in `seq 1 4`;
  do
    if [ -d "/youdata/disks/disk${i}/yd-bucket" ] && [ "$(ls -A /youdata/disks/disk${i}/yd-bucket)" ]; then
      echo "Start copying disk${i} ..."
      rsync -av /youdata/disks/disk${i}/yd-bucket /var/lib/docker/volumes/${folder}_disk${i}/_data/
      if [ "$?" -eq "0" ]; then
        echo "Finish copying disk${i} ..."
      else
        echo "Error in copying"
      fi
    fi
  done
fi
