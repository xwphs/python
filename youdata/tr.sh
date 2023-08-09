#!/bin/bash

# 通过trId搜索/youdata/logs/下各个文件夹下，近n天的TR日志里包含该trId的内容.
# 多机环境下, 请在多台机器上都执行查找.
# Usage:
#   bash tr.sh dWXc73YUnXCLYHNCY8UMSD    $1为trId, $2为空则默认搜索近1天
#   bash tr.sh dWXc73YUnXCLYHNCY8UMSD 7  $2不为空, 则默认搜索近$2天, 为7则为搜索7天

[[ -z "$2" ]] && DAY=1 || DAY=$2
find /youdata/logs/ -iname "*tr*" -type f -mtime -${DAY}  -exec echo -e "\033[1;34m""{}""\033[0m" \; -exec grep --color=auto $1 {} \;
