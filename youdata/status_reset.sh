#!/usr/bin/env bash

# (用于 LTS7.0 及之后版本)  用于在放置了LICENSE文件之后重启相关服务。
# 注意: 只适用于有数自身提供的 redis
# Usage:
#   bash status_reset.sh youdata
#   bash status_reset.sh ydswarm

function info() {
    echo -e "\033[1;34m""$@""\033[0m" >&2
}

function fatal() {
    echo -e "\033[1;31m""$@""\033[0m" >&2
    exit 1
}

function check_err() {
  RET=$?
  if [ "$RET" != "0" ]; then
    fatal "$@"
  fi
  return ${RET}
}

function update() {
    SERVICE=${STACK}_$1
    info "updating ${SERVICE}"
    docker service update --force ${STACK}_$1
    check_err "update ${SERVICE} failed"
    info "update ${SERVICE} successfully"
}

STACK=$1
if [ -z "${STACK}" ]; then
    fatal "Please provide a stack name: youdata or ydswarm"
fi

update erwin
sleep 5
update schedule
update web
update inner-web
update da
update nginx

REDIS_CLI=$(docker ps | grep "redis" | head -n 1 | awk -F ' ' {'print $1'})
info "redis container id: ${REDIS_CLI}"
if [ -z "${REDIS_CLI}" ]; then
    info "No Redis image found. Please deal with redis status."
    exit 1
fi
docker exec -it ${REDIS_CLI}  bash -c 'redis-cli -a youdata scan 0 match "da*" count 10000000 | xargs redis-cli -a youdata DEL'

