#! /bin/bash
#只适用于单机及双机

function usage()
{
  echo "usage: $0 [--overview][--check service_a service_b][--tcp container_id]"
  echo "example:"
  echo "$0: show container overview & do servie call check (ping/call)"
  echo "$0 --overview: show container overview"
  echo "$0 --check dc da: dc instances in this node call all da instances"
  echo "$0 --tcp 27153a054d: count the TCP status of the container 27153a054d"
}

function good_news() {
  echo -e "\033[1;32m""$@""\033[0m"
}

function info() {
  echo -e "\033[1;34m""$@""\033[0m" >&2
}

function warn() {
  echo -e "\033[1;33m""$@""\033[0m" >&2
}

function check_warn() {
  RET=$?
  if [ "$RET" != "0" ]; then
    warn "$@"
  fi
  return $RET
}

declare -A service_port
declare -A service_hello_api
declare -A service_instances
declare -A current_node_iptask_arr
service_port=([web]=7000 [inner-web]=7000 [schedule]=9093 [capture]=9094 [capture_cache]=9094 [chrome]=9222 [chrome_cache]=9222 [survey]=3000 [backend]=8010
  [website]=9000 [erwin]=8248 [da]=8080 [tb]=8700 [dc]=8000 [de]=8090 [insight]=8087 [hc]=8888 [smartcache]=7002)
service_hello_api=([web]="/api/dash/hello" [inner-web]="/api/dash/hello" [schedule]="/hello" [capture]="/api/hello" [capture_cache]="/api/hello"
  [chrome]="/json/version" [chrome_cache]="/json/version" [survey]="/survey/hello" [backend]="/operation/api/hello" [website]="/hello" [erwin]="/hello"
  [da]="/hello" [tb]="/status" [dc]="/hello" [de]="/hello" [insight]="/hello" [hc]="/version" [smartcache]="/cache/hello")

function basic_info() {
  STACK_NAME=$(docker stack ls | grep -E 'ydswarm|youdata' | awk '{print $1}')
  [[ -z $STACK_NAME ]] && warn "stack ydswarm or youdata does not exist." && exit 1
  SWARM_OVERLAY_NET=$(docker network ls | grep -E 'ydswarm_youdata|youdata_youdata' | awk '{print $2}')
  [[ -z $SWARM_OVERLAY_NET ]] && warn "network ydswarm_youdata or youdata_youdata  does not exist." && exit 1
  CURRENT_NODE=$(docker node ls | grep "\*" | awk '{print $3}')
  OTHER_NODE=$(docker node ls | grep -v "\*" | awk '{print $2}' | tail -n +2 | head -n 1) # 单机时为空
}
basic_info

function prepareJq() {
  [[ ! -f ./jq ]] && echo jq does not exist && exit 1
  chmod +x ./jq
  echo prepare jq done.
}

function prepareNetshoot() {
  NETSHOOT_IMAGE=$(docker images | grep netshoot | grep stable | awk '{print $1":"$2}')
  [[ -z $NETSHOOT_IMAGE ]] && warn "netshoot image does not exist." && exit 1
  docker rm -f temp_netshoot >/dev/null 2>&1
  docker run -d --net="$SWARM_OVERLAY_NET" --name="temp_netshoot" "$NETSHOOT_IMAGE" /bin/sh -c "while true;do sleep 3600; done" >/dev/null 2>&1
  check_warn
  echo prepare netshoot done.
}

function container_ip_task_map() {
  # 本机上的容器IP有哪些, 并获取对应的服务名称
  IP_TASKS=$(docker inspect "$SWARM_OVERLAY_NET" | ./jq '.[].Containers|.[]' | ./jq -r '.IPv4Address + "," + .Name')
  for IP_TASK in $IP_TASKS; do
    ip_index=$(echo $IP_TASK | cut -d ',' -f 1 | cut -d '/' -f 1)
    task_name=$(echo $IP_TASK | cut -d ',' -f 2)
    current_node_iptask_arr[$ip_index]=$task_name
  done
}

prepareJq
prepareNetshoot
container_ip_task_map

function container_overview() {
  # 找出所有Services, 并dig得到A记录
  info Containers Overview
  printf "| %-25s | %-8s | %-15s | %s \n" service mode vip instances
  SERVICES=$(docker service ls | grep "$STACK_NAME"_ | awk '{print $2}')
  for SERVICE in $SERVICES; do
    SERVICE_MODE=$(docker inspect "$SERVICE" | ./jq -r '.[]|.Spec.EndpointSpec.Mode')
    SIMPLE_SERVICE=${SERVICE/"$STACK_NAME"_/}
    if [[ "$SERVICE_MODE" == "vip" ]]; then
      VIP_IP=$(docker exec -it temp_netshoot dig +short "$SIMPLE_SERVICE" | tr -d '[:cntrl:]')
      INSTANCE_IP=$(docker exec -it temp_netshoot dig +short tasks."$SIMPLE_SERVICE" | tr '[:cntrl:]' ' ')
    else
      VIP_IP="\\"
      INSTANCE_IP=$(docker exec -it temp_netshoot dig +short tasks."$SIMPLE_SERVICE" | tr '[:cntrl:]' ' ')
    fi
    service_instances[$SIMPLE_SERVICE]=$INSTANCE_IP
    for instance in $INSTANCE_IP; do
      [[ -z ${current_node_iptask_arr[$instance]} ]] && RES="$RES $instance($OTHER_NODE)" || RES="$RES $instance($CURRENT_NODE)"
    done
    RES=$(echo $RES | sed 's/ /  /g')
    printf "| %-25s | %-8s | %-15s | %s \n" $SERVICE $SERVICE_MODE $VIP_IP "$RES"
    RES=""
  done
}

function serviceCallDetect() {
  local caller=$1
  echo "$caller service call detect start."
  shift 1
  local callees=$@

  local callerIps=${service_instances[$caller]}
  [[ -z "$callerIps" ]] && warn "service $caller instances does not exist." && return 1

  for callerip in $callerIps; do
    local calleriptask=${current_node_iptask_arr[$callerip]}
    if [[ -n "$calleriptask" ]]; then
      local cid=$(docker run -d --net container:"$calleriptask" "$NETSHOOT_IMAGE" /bin/sh -c "while true;do sleep 3600; done")
      for callee in $callees; do
        local calleeIps=${service_instances[$callee]}
        for calleeip in $calleeIps; do
          # do ping
          if docker exec -it $cid ping -c 3 -i 0.3 -W 5 $calleeip >/dev/null; then
            good_news "$callerip ($caller) -> $calleeip ($callee) ping success"
          else
            warn "$callerip ($caller) -> $calleeip ($callee) ping failed"
          fi
          # do curl
          calleeCurlUrl="$calleeip:${service_port[$callee]}${service_hello_api[$callee]}"
          if docker exec -it $cid curl --connect-timeout 5 -m 8 -sf -o /dev/null $calleeCurlUrl; then
            good_news "$callerip ($caller) curl $calleeCurlUrl ($callee) sueccess"
          else
            warn "$callerip ($caller) curl $calleeCurlUrl ($callee) failed"
          fi
        done
      done
      docker rm -f $cid >/dev/null 2>&1
    fi
  done
}

function allServiceCallDetect() {
  info "Service Call Detect (Node $CURRENT_NODE)"
  serviceCallDetect nginx web inner-web survey website backend
  serviceCallDetect web insight dc de hc schedule
  serviceCallDetect inner-web smartcache
  serviceCallDetect schedule web capture capture_cache erwin
  serviceCallDetect capture chrome
  serviceCallDetect capture_cache chrome_cache
  serviceCallDetect backend web
  serviceCallDetect smartcache inner-web
  serviceCallDetect insight dc
  serviceCallDetect dc da
  serviceCallDetect de da
  serviceCallDetect da tb
  serviceCallDetect hc da
  serviceCallDetect erwin web schedule da
}

function clean() {
  docker rm -f temp_netshoot >/dev/null 2>&1
}

function tcp_statistics() {
  cid=$1
  container_pid=$(docker inspect -f {{.State.Pid}} $cid)
  info "tcp status:"
  nsenter -n -t $container_pid netstat -ant | awk '/^tcp/ {++S[$NF]} END {for(a in S)  print a,S[a]}'
  info "tcp foreign address:"
  nsenter -n -t $container_pid netstat -ant | awk '/^tcp/ {print $5}' | sort | uniq -c | sed 's/  */ /g'| sort -rn
}

case "$1" in
  -h|--help) usage; ;;
  -o|--overview) container_overview; ;;
  -c|--check) container_overview; serviceCallDetect $2 $3; ;;
  -t|--tcp) tcp_statistics $2; ;;
  *)  container_overview; allServiceCallDetect; ;;
esac
clean
