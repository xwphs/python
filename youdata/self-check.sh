#!/usr/bin/env bash
#
# Usage:
#   1. 收集环境/配置信息/有数服务健康状况:  self-check.sh collect slave_host
#   2. 检查有数服务健康状况:               self-check.sh check slave_host
#

if [ "$1" != "collect" ] && [ "$1" != "check" ]; then
    echo "Usage:"
    echo "1. collect env/conf/youdata services health:  self-check.sh collect slave_host"
    echo "2. check youdata services health:             self-check.sh check slave_host"
    exit 0
fi

source utils.sh
source check_services.sh --source-only

BASE_DIR="/youdata/installer"
DUAL_DEPLOY="dual deploy"
SINGLE_DEPLOY="single deploy"
SLAVE=$2
TAR="self-check.tar"
YES="Yes"
NO="No"
MIN_DOCKER_V=50
MIN_YOUDATA_V=100
YOUDATA_PATH="/youdata/"
COMPOSE_MASTER_YAML="${BASE_DIR}/docker-compose.master.yaml"
COMPOSE_SLAVE_YAML="${BASE_DIR}/docker-compose.slave.yaml"
#GET_INTERFACE_CMD="ip a | grep UP | grep -v veth | grep -v lo | grep -v docker0 | grep -v docker_gwbridge | grep -v br- | grep -v NO-CARRIER | cut -f 2 -d :"

version=$($DOCKER ps | grep "web:lts-" | head -n 1 | awk -F ' ' {'print $2'} | cut -f 2 -d "-")
version_no_point=${version/./}
docker_volume=$($DOCKER info >&1 2>/dev/null | grep "Docker Root" | cut -f 2 -d ":")
check_dir="self-check_"$(date +%Y%m%d%H%M%S)
collect_dir="${check_dir}/collect/"
collect_log="${check_dir}/collect/collect.log"
service_log="${check_dir}/service/service.log"

if [ $STACK == "ydswarm" ]; then
    deploy_mode=$DUAL_DEPLOY
    yaml_path=${BASE_DIR}/docker-stack.ydswarm${version_no_point}.yaml
else
    deploy_mode=$SINGLE_DEPLOY
    yaml_path=${BASE_DIR}/docker-stack.youdata${version_no_point}.yaml
fi

# 双机部署下检查能否 ssh 免密
if [ "$deploy_mode" == "$DUAL_DEPLOY" ]; then

    if [ -z "$SLAVE" ]; then
        warn "To check slave deployment, please supply slave host or slave ip:"
        read -p 'Slave host or slave ip: ' SLAVE
    fi

    ssh -q ${SLAVE} exit
    if [ $? -eq 0 ]; then
        slave_ssh_login=$YES
    else
        slave_ssh_login=$NO
        warn "CAN NOT ssh to ${SLAVE}"
        choice=$(get_yn_choice "Do you want to continue?")
        if [ "${choice}" = "n" ]; then
            exit 1
        fi
    fi
fi

# 获取下列信息：
# - 部署版本
# - 部署模式
# - 是否部署 MPP
# - 是否部署单点登录
function get_youdata_deploy_info() {
    info "Deploy Version: $version"
    info "Deploy Mode: $deploy_mode"

    # 获取 DE 环境变量 MPP:xxx 中的 xxx
    mpp=$(grep MPP $yaml_path | head -n 1 | cut -f 2 -d ":")
    mpp=$(trim_string $mpp)
    if [ "$mpp" == postgres* ]; then
        deploy_mpp=$YES
    else
        deploy_mpp=$NO
    fi
    info "Deploy MPP: $deploy_mpp"

    # 获取 WEB 环境变量 LOGIN_TYPE
    login_type=$(grep LOGIN_TYPE $yaml_path | head -n 1 | cut -f 1 -d ":")
    login_type=$(trim_string $login_type)
    if [ "$login_type" == "#LOGIN_TYPE" ]; then
        deploy_sso=$NO
    else
        deploy_sso=$YES
    fi
    info "Deploy SSO: $deploy_sso"
}

# 保存下列配置文件
# - docker-stack.youdata${v}.yaml / docker-stack.ydswarm${v}.yaml
# - docker-stack.monitor${v}${ha}.yaml
# - docker-stack.logService{v}.yaml
# - docker-compose.master.yaml / docker-compose.slave.yaml
# - nginx.conf.tpl
function save_configs() {
    info "Save yamls - start"

    if [ -f ${yaml_path} ]; then
        cp ${yaml_path} $1
        good_news "Save BI stack yaml success"
    else
        warn "BI stack yaml is not in $BASE_DIR"
    fi

    # 早部署 lts-6.2 的客户 monitor 是 56 版本，晚部署的是 62 版本
    if [ "$deploy_mode" == "$DUAL_DEPLOY" ]; then
        ha="HA"
    else
        ha=""
    fi
    if [ $version_no_point == "62" ]; then
        if [ -f ${BASE_DIR}/docker-stack.monitor56${ha}.yaml ]; then
            cp ${BASE_DIR}/docker-stack.monitor56${ha}.yaml $1
            good_news "Save monitor56 yaml success"
        else
            if [ -f ${BASE_DIR}/docker-stack.monitor62${ha}.yaml ]; then
                cp ${BASE_DIR}/docker-stack.monitor62${ha}.yaml $1
                good_news "Save monitor62 yaml success"
            else
                warn "monitor stack yaml is not in $BASE_DIR"
            fi
        fi
    else
        if [ -f ${BASE_DIR}/docker-stack.monitor${version_no_point}${ha}.yaml ]; then
            cp ${BASE_DIR}/docker-stack.monitor${version_no_point}${ha}.yaml $1
            good_news "Save monitor yaml success"
        else
            warn "monitor stack yaml is not in $BASE_DIR"
        fi
    fi

    if [ -f ${BASE_DIR}/docker-stack.logService${version_no_point}.yaml ]; then
        cp ${BASE_DIR}/docker-stack.logService${version_no_point}.yaml $1
        good_news "Save log stack yaml success"
    else
        warn "log stack yaml is not in $BASE_DIR"
    fi

    if [ "$deploy_mode" == "$DUAL_DEPLOY" ]; then
        if [ -f ${BASE_DIR}/docker-compose.master.yaml ]; then
            cp ${BASE_DIR}/docker-compose.master.yaml $1
            good_news "Save docker-compose.master.yaml success"
        else
            warn "docker-compose.master.yaml is not in $BASE_DIR"
        fi

        # 收集从机信息需要双机间 ssh 免密，默认使用 root 账号
        if [ "$deploy_mode" == "$DUAL_DEPLOY" ]; then
            if [ "$slave_ssh_login" == $YES ]; then
                $SCP root@${SLAVE}:${BASE_DIR}/docker-compose.slave.yaml $1
                if [ $? == "0" ]; then
                    good_news "Save $SLAVE docker-compose.slave.yaml success"
                else
                    error "Copy docker-compose.slave.yaml from $SLAVE failed"
                fi
            else
                warn "Because CAN NOT ssh to ${SLAVE}, collecting slave docker-compose.slave.yaml stop"
            fi
        fi
    fi
    info "Save yamls - end"

    info "Save Nginx conf - start"
    if [ -f ${BASE_DIR}/nginx.conf.tpl ]; then
        cp ${BASE_DIR}/nginx.conf.tpl ${1}/nginx.conf.master.tpl
        good_news "Save master nginx.conf.tpl success"
    else
        warn "nginx conf is not in $BASE_DIR"
    fi

    if [ "$deploy_mode" == "$DUAL_DEPLOY" ]; then
        if [ "$slave_ssh_login" == $YES ]; then
            $SCP root@${SLAVE}:${BASE_DIR}/nginx.conf.tpl ${1}/nginx.conf.slave.tpl
            if [ $? == "0" ]; then
                good_news "Save slave(${SLAVE}) nginx.conf.tpl success"
            else
                error "Copy nginx.conf.tpl from $SLAVE failed"
            fi
        else
            warn "Because CAN NOT ssh to ${SLAVE}, collecting slave nginx.conf.tpl stop"
        fi
    fi
    info "Save Nginx conf - end"
}

# 获取下列宿主机（主从）信息：
# - crontab 任务
# - 磁盘使用情况
# - 主网卡信息
function get_host_info() {
    info "Check master crontab"
    crontab -l
    if [ "$deploy_mode" == "$DUAL_DEPLOY" ]; then
        if [ "$slave_ssh_login" == $YES ]; then
            info "Check slave crontab"
            ssh ${SLAVE} "crontab -l"
        else
            warn "Because CAN NOT ssh to ${SLAVE}, checking slave crontab stop"
        fi
    fi

    info "Check master disks volumes"
    df -h | grep -v overlay | grep -v shm
    info "Docker volumes:"
    df -h $docker_volume
    info "Youdata volumes:"
    df -h /youdata

    if [ "$deploy_mode" == "$DUAL_DEPLOY" ]; then
        if [ "$slave_ssh_login" == $YES ]; then
            info "Check slave disks volumes"
            ssh ${SLAVE} "df -h | grep -v overlay | grep -v shm"
            info "Docker volumes(${SLAVE}):"
            slave_docker_v_path=$(ssh ${SLAVE} "$DOCKER info >&1 2>/dev/null | grep 'Docker Root' | cut -f 2 -d ':'")
            ssh ${SLAVE} "df -h $slave_docker_v_path"
            info "Youdata volumes(${SLAVE}):"
            ssh ${SLAVE} "df -h /youdata"
        else
            warn "Because CAN NOT ssh to ${SLAVE}, checking slave disks volumes stop"
        fi
    fi

    info "Check master Ethernet interface"
    master_interface=$(ip a | grep UP | grep -v veth | grep -v lo | grep -v docker0 | grep -v docker_gwbridge | grep -v br- | grep -v NO-CARRIER | cut -f 2 -d :)
    ip a show dev $master_interface

    if [ "$deploy_mode" == "$DUAL_DEPLOY" ]; then
        if [ "$slave_ssh_login" == $YES ]; then
            info "Check slave Ethernet interface"
            slave_interface=$(ssh ${SLAVE} "ip a | grep UP | grep -v veth | grep -v lo | grep -v docker0 | grep -v docker_gwbridge | grep -v br- | grep -v NO-CARRIER | cut -f 2 -d :")
            ssh ${SLAVE} "ip a show dev $slave_interface"
        else
            warn "Because CAN NOT ssh to ${SLAVE}, checking slave Ethernet interface stops."
        fi
    fi
}

function service() {
    check_port
    check_inter_services
    check_stack_services
}

function initialize_min_volume() {
    # 检查 docker 目录和有数目录是否在同一块磁盘上
    if [ "$1" == "$2" ]; then
        # 如果 docker 目录和有数目录在同一块磁盘上，$MIN_DOCKER_V 和 $MIN_YOUDATA_V 都改为两者的和
        MIN_DOCKER_VOLUMES=$(expr $MIN_DOCKER_V + $MIN_YOUDATA_V)
        MIN_YOUDATA_VOLUMES=$MIN_DOCKER_VOLUMES
    else
        MIN_DOCKER_VOLUMES=$MIN_DOCKER_V
        MIN_YOUDATA_VOLUMES=$MIN_YOUDATA_V
    fi
}

function check_volume() {
    volume=$(df -B G $1 | tail -1 | awk '{print $4}')
    volume_numeric=$(rstrip $volume "G")
    # 如果 volume 为小数，只取整数部分
    if [ ${volume_numeric%%.*} -ge $2 ]; then
        good_news "Available disk volume of $1 is ${volume}."
    else
        error "Not enough disk volume for $1, available volume is ${volume}. We recommend that the available volume should be above ${2}G."
    fi
}

function check_slave_volume() {
    slave_volume=$(ssh ${SLAVE} "df -B G $1 | tail -1" | awk '{print $4}')
    slave_volume_numeric=$(rstrip $slave_volume "G")
    # 如果 volume 为小数，只取整数部分
    if [ ${slave_volume_numeric%%.*} -ge $2 ]; then
        good_news "Available disk volume of $1 in ${SLAVE} is ${slave_volume}."
    else
        error "Not enough disk volume for $1 in ${SLAVE}, available volume is ${slave_volume}. We recommend that the available volume should be above ${2}G."
    fi
}

function check_crontab() {
    job=$(crontab -l 2>/dev/null | grep $1)
    if [ -z "$job" ]; then
        warn "No job executing $1 in crontab!"
    else
        if [[ "$job" == \#* ]]; then
            warn "Job fo executing $1 is commented!"
        else
            good_news "Job fo executing $1 is set: ${job}."
        fi
    fi
}

function check_slave_crontab() {
    job=$(ssh ${SLAVE} "crontab -l 2>/dev/null | grep $1")
    if [ -z "$job" ]; then
        warn "No job executing $1 in crontab in ${SLAVE}!"
    else
        if [[ "$job" == \#* ]]; then
            warn "Job fo executing $1 is commented!"
        else
            good_news "Job fo executing $1 is set in ${SLAVE}: ${job}."
        fi
    fi
}

function check_vip() {
    info "Checking $2 VIP..."
    interface=$(ip a | grep UP | grep -v veth | grep -v lo | grep -v docker0 | grep -v docker_gwbridge | grep -v br- | grep -v NO-CARRIER | cut -f 2 -d :)
    IFS=' ' read -ra interface_arr <<<$interface
    if [ ${#interface_arr[@]} -gt 1 ]; then
        # 如果找到多于一个网络接口
        for i in "${!interface_arr[@]}"; do
            vip_interface=$(ip a show dev ${interface_arr[i]} | grep $1)
            if [ -z "$vip_interface" ]; then
                warn "$2 VIP $1 is NOT on the interface ${interface_arr[i]}!"
            else
                good_news "$2 VIP $1 is on the interface ${interface_arr[i]}."
                break
            fi
        done
    else
        vip_interface=$(ip a show dev ${interface} | grep $1)
        if [ -z "$vip_interface" ]; then
            error "$2 VIP $1 is NOT on the interface ${interface}!"
        else
            good_news "$2 VIP $1 is on the interface ${interface}."
        fi
    fi
}

function check_slave_vip() {
    info "Checking $2 VIP on slave ${SLAVE}..."
    slave_interface=$(ssh ${SLAVE} "ip a | grep UP | grep -v veth | grep -v lo | grep -v docker0 | grep -v docker_gwbridge | grep -v br- | grep -v NO-CARRIER | cut -f 2 -d :")
    IFS=' ' read -ra interface_arr <<<$slave_interface
    if [ ${#interface_arr[@]} -gt 1 ]; then
        # 如果找到多于一个网络接口
        for i in "${!interface_arr[@]}"; do
            vip_interface=$(ip a show dev ${interface_arr[i]} | grep $1)
            if [ -z "$vip_interface" ]; then
                good_news "$2 VIP $1 is not on the interface ${interface_arr[i]} of ${SLAVE}."
            else
                warn "$2 VIP $1 is ON the interface ${interface_arr[i]} of ${SLAVE}!"
            fi
        done
    else
        vip_slave_interface=$(ssh ${SLAVE} "ip a show dev $slave_interface|grep $1")
        if [ -z "$vip_slave_interface" ]; then
            good_news "$2 VIP $1 is not on the interface ${slave_interface} of ${SLAVE}."
        else
            error "$2 VIP $1 is ON the interface ${slave_interface} of ${SLAVE}!"
        fi
    fi
}

# 根据节点状态及同步状态打印 master 日志信息
function check_mysqlpaas_master() {
    info "Checking MySQL Master node..."
    if [ $1 == "ok" ]; then
        good_news "The status of master is $1."
    else
        error "The status of master is $1!"
    fi

    if [ $2 == "sync" ]; then
        good_news "The sync status of master is $2."
    else
        error "The sync status of master is $2!"
    fi
}

# 根据节点状态及同步状态打印 slave 日志信息
function check_mysqlpaas_slave() {
    info "Checking MySQL Slave node..."
    if [ $1 == "ok" ]; then
        good_news "The status of slave is $1."
    else
        error "The status of slave is $1!"
    fi

    if [ $2 == "ok" ]; then
        good_news "The sync status of slave is $2."
    else
        error "The sync status of slave is $2!"
    fi
}

if [ "$1" == "collect" ]; then
    date=$(date "+%Y-%m-%d %T")
    info "Check Date: $date"

    mkdir -p $check_dir/collect

    get_youdata_deploy_info | tee -a $collect_log
    save_configs $collect_dir | tee -a $collect_log
    get_host_info | tee -a $collect_log

    info_title "Collect Docker info" $collect_log
    $DOCKER info >>$collect_log

    info_title "Collect sysctl.conf" $collect_log
    cat /etc/sysctl.conf >>$collect_log

    info_title "Collect iptable" $collect_log
    iptables-save >>$collect_log

    # 收集有数服务运行信息
    mkdir -p $check_dir/service
    service | tee -a $service_log

    info_title "Collect version api" $service_log
    $CURL -sb -H "Accept: application/json" localhost/api/dash/version | $PYTHON -m json.tool >>$service_log

    info_title "Collect Redis info" $service_log
    $DOCKER ps | grep "redis-ha" | tee -a $service_log

    # 只对万象 MySQL 进行信息收集
    info_title "Collect MySQL PaaS info" $service_log
    $DOCKER ps | grep "mysqlpaas-node" | tee -a $service_log
    $CURL -s ydqa2:8081/api/core/v3/clusters | $PYTHON -m json.tool >>$service_log

    if [ -f ${TAR} ]; then
        mv ${TAR} ${check_dir}.tar
    fi
    tar -cvf ${TAR} $check_dir
    #rm -rf $check_dir
    exit 0
fi

# 自检服务检查下列项：
# 1. 端口能否 curl 通 80 443 8010 9090 端口
# 2. swarm 内部各服务的 hello 接口能否 curl 通
# 3. 各服务的 replicas 数量是否和声明的一致
# 4. 宿主机的 docker root dir 和 youdata 目录磁盘剩余空间是否足够
# 5. crontab 是否配置日志定时删除脚本，MySQL 定时备份脚本
# 双机：
# - 在备机上检查以上第 1，4，5 点
# - 以 docker-compose 启动的容器是否正常运行
# - mysql/redis vip 是否在主机上
# - mysql/redis vip 是否不在从机上
# - 网易万象集群健康状况
# - 网易万象是否配置定时备份
# - redis 能够提供服务？
# - store 检查？
if [ "$1" == "check" ]; then
    check_port $SLAVE
    check_inter_services
    check_stack_services

    info "Checking docker volumes..."
    docker_disk=$(df -h $docker_volume | tail -1 | awk '{print $1}')
    youdata_disk=$(df -h $YOUDATA_PATH | tail -1 | awk '{print $1}')
    initialize_min_volume $docker_disk $youdata_disk
    check_volume $docker_volume $MIN_DOCKER_VOLUMES

    info "Checking youdata volumes..."
    check_volume $YOUDATA_PATH $MIN_YOUDATA_VOLUMES

    if [ "$deploy_mode" == "$DUAL_DEPLOY" ]; then
        info "Checking slave docker and youdata volumes..."
        if [ "$slave_ssh_login" == $YES ]; then
            info "Checking slave docker volumes..."
            slave_docker_v_path=$(ssh ${SLAVE} "$DOCKER info >&1 2>/dev/null | grep 'Docker Root' | cut -f 2 -d ':'")
            slave_docker_disk=$(ssh ${SLAVE} "df -h $docker_volume | tail -1 | awk '{print $1}'")
            slave_youdata_disk=$(ssh ${SLAVE} "df -h $YOUDATA_PATH | tail -1 | awk '{print $1}'")
            initialize_min_volume $slave_docker_disk $slave_youdata_disk
            check_slave_volume $slave_docker_v_path $MIN_DOCKER_VOLUMES
            check_slave_volume $YOUDATA_PATH $MIN_YOUDATA_VOLUMES
        else
            warn "Because CAN NOT ssh to ${SLAVE}, checking slave docker volumes stops."
            warn "Because CAN NOT ssh to ${SLAVE}, checking slave youdata volumes stops."
        fi
    fi

    info "Checking delete logs job..."
    check_crontab "delete_logs.sh"

    if [ "$deploy_mode" == "$DUAL_DEPLOY" ]; then
        if [ "$slave_ssh_login" == $YES ]; then
            info "Checking slave delete logs job..."
            check_slave_crontab "delete_logs.sh"
        else
            warn "Because CAN NOT ssh to ${SLAVE}, checking slave youdata volumes stops."
        fi
    fi

    if [ "$deploy_mode" == "$SINGLE_DEPLOY" ]; then
        # 检查单机 MySQL 定时备份
        info "Checking MySQL backup job..."
        mysql_backup_job=$(crontab -l 2>/dev/null | grep backup_single.sh)
        mysql_backup=$(crontab -l 2>/dev/null | grep backup_single.sh | cut -f 7 -d " ")

        if [ -z "$mysql_backup" ]; then
            error "MySQL backup job is NOT set!"
        else
            if [[ "$mysql_backup_job" == \#* ]]; then
                error "MySQL backup job is commented!"
            else
                good_news "MySQL backup job is set: ${mysql_backup_job}."
                choice=$(get_yn_choice "Do you want to test MySQL backup script?")
                if [ "${choice}" = "y" ]; then
                    info "Test MySQL backup script..."
                    "$BASH" "$mysql_backup"
                    if [ $? == "0" ]; then
                        good_news "Test MySQL backup script success."
                    else
                        error "Test MySQL backup script failed!"
                    fi

                    if [ -f /youdata/db_data_bak/backup.log ]; then
                        info "MySQL backup log:"
                        tail -n 4 /youdata/db_data_bak/backup.log
                    fi
                fi
            fi
        fi
    fi

    # 双机检查
    if [ "$deploy_mode" == "$DUAL_DEPLOY" ]; then
        info "Checking master MySQL/Redis services..."
        docker-compose -f $COMPOSE_MASTER_YAML ps -q | while read -r c_id; do
            c_status=$($DOCKER ps --filter id=$c_id --format "{{.Status}}")
            c_name=$($DOCKER ps --filter id=$c_id --format "{{.Names}}")
            # 注意下面必须用 [[ ]] 来做条件判断
            if [[ $c_status == *"Up"* ]]; then
                good_news "$c_name $c_status"
            else
                error "$c_name $c_status"
            fi
        done

        info "Checking slave MySQL/Redis services..."
        if [ "$slave_ssh_login" == $YES ]; then
            # 这里不可以用 master 的检测方法，用 while 遍历 stdout，因为循环里的 ssh 会打开新的 tty，循环外的 stdout 就丢失了
            c_ids=$(ssh ${SLAVE} "docker-compose -f $COMPOSE_SLAVE_YAML ps -q")
            for c_id in $c_ids; do
                c_status=$(ssh ${SLAVE} "$DOCKER ps -a --filter id=$c_id --format '{{.Status}}'")
                c_name=$(ssh ${SLAVE} "$DOCKER ps -a --filter id=$c_id --format '{{.Names}}'")
                if [[ $c_status == *"Up"* ]]; then
                    good_news "$c_name $c_status"
                else
                    if [ ! -z "$c_name" ] && [ ! -z "$c_status" ]; then
                        error "$c_name $c_status"
                    else
                        error "Can not get container info, please run 'docker-compose -f /youdata/installer/docker-compose.slave.yaml ps' on ${SLAVE}"
                    fi
                fi
            done
        else
            warn "Because CAN NOT ssh to ${SLAVE}, checking slave MySQL/Redis services stops."
        fi

        # DB:mysql://youdata:Yd@TEST5@1.1.1.2:3306/youdata, 先翻转字符串，取出以 @ 分割的第一个子串，再取出以 : 分割的第二个子串，最后翻转回来
        mysql_vip=$(cat ${yaml_path} | grep "DB" | head -n 1 | rev | cut -f 1 -d @ | cut -f 2 -d : | rev)
        redis_vip=$(cat ${yaml_path} | grep "REDIS" | head -n 1 | rev | cut -f 1 -d @ | cut -f 2 -d : | rev)

        check_vip $mysql_vip "MySQL"
        check_vip $redis_vip "Redis"

        if [ "$slave_ssh_login" == $YES ]; then
            check_slave_vip $mysql_vip "MySQL"
            check_slave_vip $redis_vip "Redis"
        else
            warn "Because CAN NOT ssh to ${SLAVE}, checking MySQL/Redis VIP on slave stops."
        fi

        # 只检测万象
        mysql_paas=$($DOCKER ps | grep "mysqlpaas-node")
        if [ -z "$mysql_paas" ]; then
            warn "MySQL_PAAS is NOT deployed, checking MySQL stops."
        else
            cluster=$(curl -s ${SLAVE}:8081/api/core/v3/clusters)
            if [ $? == "0" ]; then
                role1=$(echo ${cluster} | python -c 'import sys, json; print json.load(sys.stdin)["clusters"][0]["mysqlds"][0]["role"]')
                status1=$(echo ${cluster} | python -c 'import sys, json; print json.load(sys.stdin)["clusters"][0]["mysqlds"][0]["mysqldStatus"]')
                replication_status1=$(echo ${cluster} | python -c 'import sys, json; print json.load(sys.stdin)["clusters"][0]["mysqlds"][0]["replicationStatus"]')
                status2=$(echo ${cluster} | python -c 'import sys, json; print json.load(sys.stdin)["clusters"][0]["mysqlds"][1]["mysqldStatus"]')
                replication_status2=$(echo ${cluster} | python -c 'import sys, json; print json.load(sys.stdin)["clusters"][0]["mysqlds"][1]["replicationStatus"]')

                if [ $role1 == "master" ]; then
                    check_mysqlpaas_master $status1 $replication_status1
                    check_mysqlpaas_slave $status2 $replication_status2
                else
                    check_mysqlpaas_master $status2 $replication_status2
                    check_mysqlpaas_slave $status1 $replication_status1
                fi

                info "Checking MySQL auto backup..."
                auto_backup=$(echo ${cluster} | python -c 'import sys, json; print json.load(sys.stdin)["clusters"][0]["backupConfig"]["enableAutoBackup"]')
                if [ $auto_backup == "True" ]; then
                    good_news "MySQL auto backup is turned on."
                else
                    warn "MySQL auto backup is turned off!"
                fi
            else
                error "MySQL Manager Service is not running or doesn't listen to port 8081 on ${SLAVE}."
            fi
        fi
    fi

    # if [ -f ${TAR} ]; then
    #    mv ${TAR} ${check_dir}.tar
    # fi
    # tar -cvf ${TAR} $check_dir
    # rm -rf $check_dir
    exit 0
fi
