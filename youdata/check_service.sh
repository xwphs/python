#!/usr/bin/env bash
#
# Usage:
#   1. 不加参数：bash check_services.sh，source 和脚本同一目录下的 utils.sh
#   2. 加参数 utils.sh 所在目录的绝对路径（不带最后的斜杠），如 bash /youdata/scripts/check_services.sh /youdata/scripts，source 指定目录下的 utils.sh 脚本
#      主要用在 youdata_installer.sh 里，因为 youdata_installer.sh 里使用 ssh 运行脚本，新建的 ttl 里默认路径不存在 utils.sh
#   3. 加参数 --source-only，如 source check_services.sh --source-only，主要用在 self-check.sh 里，为了调用脚本中定义的函数而不运行 main 函数
#

if [ ! -z $1 ] && [ "${1}" != "--source-only" ]; then
    source ${1}/utils.sh
else
    source utils.sh
fi

[ ! -z "$CURL" ]
check_err "Curl variable not set."

HOSTS="127.0.0.1"
PORTS="80 443 8010 9090"
RETURN=0

# 保存 main 方法的返回值
function save_return() {
    if [ "$?" != "0" ]; then
        RETURN=1
    fi
}

function export_return() {
    return $RETURN
}

# 根据 $1 check warm
function warm_if_param_not_ok() {
    RET=$1
    shift
    if [ "$RET" != "0" ]; then
        warn "$@"
    fi
    return $RET
}

# 根据 $? check warm
function warm_if_ret_not_ok() {
    RET=$?
    if [ "$RET" != "0" ]; then
        warn "$@"
    fi
    return $RET
}

# Check if host ports are accessible
# 可传入参数：
#  1. 除了 127.0.0.1 以外需要检验端口的主机 ip 或 host
#  2. check，只输出错误信息
function check_port() {
    if ! [ -z "$1" ]; then
        HOSTS="127.0.0.1 $1"
    fi
    for h in $HOSTS; do
        info "Checking ports of $h..."
        for p in $PORTS; do
            if [ "$p" = "443" ]; then
                PROTO="https"
            else
                PROTO="http"
            fi
            $CURL --connect-timeout 3 -ksSL "$PROTO://$h:$p" >/dev/null 2>&1
            ret=$?
            if [ "$2" == "check" ]; then
                warm_if_param_not_ok $ret "Port $p is not accessible."
            else
                warm_if_param_not_ok $ret "Port $p is not accessible." && good_news "Port $p is accessible."
            fi
        done
    done
}

# Check inter-container communications
# 可传入一个参数：check，只输出错误信息
function check_inter_services() {
    info "Check inter-container communications on this node..."
    PROXY=nginx
    PROXYID=$($DOCKER ps --format "{{.ID}} {{.Label \"com.docker.swarm.service.name\"}}" | grep "$PROXY" | head -n 1 | awk '{print $1}')
    [ ! -z "$PROXYID" ]
    warm_if_ret_not_ok "Cannot find proxy container '$PROXY' on this node. Skipping this test..."
    if [ "$?" = "0" ]; then
        PROXYNAME=$($DOCKER ps --format "{{.ID}} {{.Label \"com.docker.swarm.service.name\"}}" | grep "$PROXY" | head -n 1)
        info "Proxy through: $PROXYNAME"
        ISVRS="web:7000/hello inner-web:7000/hello schedule:9093/hello survey:3000/survey/hello backend:8010/hello website:9000 da:8080/hello tb:8700/status dc:8000/hello de:8090/hello
    insight:8087/hello hc:8888/version"
        for isvr in $ISVRS; do
            $DOCKER exec $PROXYID wget -q -O- "$isvr" >/dev/null
            ret=$?
            if [ "$1" == "check" ]; then
                warm_if_param_not_ok $ret "Checking $isvr: failed."
            else
                warm_if_param_not_ok $ret "Checking $isvr: failed." && good_news "Checking $isvr: ok."
            fi
            save_return
        done
    fi
}

# Check if all services are up
# 可传入一个参数：check，只输出错误信息
function check_stack_services() {
    info "Check all services status on this node..."
    if [ "$MASTER" = "1" ]; then
        warn "Skipping remaining tests on non-master node..."
        export_return
        exit $?
    fi

    STACKS=$($DOCKER stack ls --format "{{.Name}}")
    check_err "Failed to get stacks."

    [ ! -z "$STACKS" ]
    check_err "No stack found."

    for s in $STACKS; do
        info "Checking services in stack '$s'..."
        SVRS=$($DOCKER service ls --format "{{.Name}}" | grep "$s")
        for svr in $SVRS; do
            TYPE=$($DOCKER service ls | grep "$svr" | awk '{print $3}')
            if [ "$TYPE" = "global" ]; then
                NREPLICA=$($DOCKER node ls | grep Active | wc -l)
            else
                NREPLICA=$($DOCKER service inspect --format "{{.Spec.Mode.Replicated.Replicas}}" "$svr")
            fi
            NRUNNING=$($DOCKER service ps -f "desired-state=running" "$svr" | grep "$svr\." | wc -l)
            if [ "$NRUNNING" = "$NREPLICA" ]; then
                if [ "$1" != "check" ]; then
                    good_news "$svr is up ($NRUNNING/$NREPLICA)."
                fi
            else
                warn "$svr is not up yet ($NRUNNING/$NREPLICA)."
                save_return
            fi
        done
    done
}

function main() {
    check_port
    check_inter_services
    check_stack_services

    export_return
}

if [ "${1}" != "--source-only" ]; then
    main
fi
