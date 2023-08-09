#!/usr/bin/env bash
#
# example: bash store.sh [check|heal|backup backup_dir|restore restore_dir]
#

NEW_MC_VERSION="RELEASE.2021-06-13T17-48-22Z"
BASE_DIR="/youdata/installer"
LOG="/youdata/installer/store.log"
HEAL_LOG="/youdata/installer/store_heal.log"
MC="/youdata/installer/mc"
MC_USER="PJ99D7K3OAFS732PS1PZ"
MC_PASS="+CGdFGEu4tQraicN45rFmFRL5wjaNnUF2OYUlQuQ"
LINE="======================================"
STORE_ID=$(docker ps | grep store | awk -F ' ' {'print $1'})
UPLOAD_TEST_FILE_NAME="store_test_upload"
DOWNLOAD_TEST_FILE_NAME="store_test_download"
UPLOAD_TEST_FILE=${BASE_DIR}/${UPLOAD_TEST_FILE_NAME}
DOWNLOAD_TEST_FILE=${BASE_DIR}/${DOWNLOAD_TEST_FILE_NAME}

if [ ! -f $MC ]; then
    echo "mc is not in path: $MC"
    exit 1
fi

chmod +x $MC

mc_version=$($MC -v | awk '{print $3}')

minio_host=$($MC config host ls | grep "store")
if [ -z "$minio_host" ]; then
    $MC config host add store http://localhost:9090 $MC_USER $MC_PASS
fi

function log() {
    echo "$@" 2>&1 | tee -a $LOG
}

function yd_public_policy_set() {
  if [[ "$NEW_MC_VERSION" = "$mc_version" ]]; then
    $MC policy set-json /youdata/scripts/store_ydpublic_config.json store/yd-public
  else
    $MC policy /youdata/scripts/store_ydpublic_config.json store/yd-public
  fi
}

function yd_bucket_policy_set() {
  if [[ "$NEW_MC_VERSION" = "$mc_version" ]]; then
    $MC policy set-json /youdata/scripts/store_ydbucket_config.json store/yd-bucket
  else
    $MC policy /youdata/scripts/store_ydbucket_config.json store/yd-bucket
  fi
}

function check() {
    if [ -z $LOG ]; then
        touch $LOG
    fi

    log $(date "+%Y-%m-%d %H:%M:%S")
    log "store info:"
    msg=$($MC admin info store)
    log "$msg"
    log $LINE
    STORE_ID=$(docker ps | grep store | awk -F ' ' {'print $1'})
    msg=$(docker logs $STORE_ID)
    log "Store container log:"
    log "$msg"
    log $LINE

    log "Buckets info:"
    buckets=$($MC ls store)
    log "$buckets"
    log $LINE

    log "yd-bucket info:"
    objects=$($MC ls store/yd-bucket)
    log "$objects"
    log $LINE

    log "yd-public info:"
    objects=$($MC ls store/yd-public)
    log "$objects"
    log $LINE

    grant_bucket_policy
    log $LINE
    upload_test
    log $LINE
    download_test
    log $LINE
    remove_test
    log $LINE

    # clean tests
    rm -f "$UPLOAD_TEST_FILE"
    rm -f "$DOWNLOAD_TEST_FILE"
}

function grant_bucket_policy() {
    yd_bucket=$($MC ls store | grep "yd-bucket")
    if [ -z "$yd_bucket" ]; then
        $MC mb store/yd-bucket
    fi

    log "grant custom policy to yd-bucket"
    yd_bucket_policy_set
    if [ $? == "0" ]; then
        log "grant custom policy to yd-bucket success"
    else
        log "grant custom policy to yd-bucket failed!"
    fi
    
    yd_public=$($MC ls store | grep "yd-public")
    if [ -z "$yd_public" ]; then
        $MC mb store/yd-public
    fi

    log "grant custom policy to yd-public"
    yd_public_policy_set
    if [ $? == "0" ]; then
        log "grant custom policy to yd-public success"
    else
        log "grant custom policy to yd-public failed!"
    fi
}

function upload_test() {
    log "Test upload file"
    touch $UPLOAD_TEST_FILE
    echo "test store upload" >$UPLOAD_TEST_FILE
    msg=$($MC cp $UPLOAD_TEST_FILE store/yd-public)
    if [ $? != 0 ]; then
        log "Upload test fail!"
        log "$msg"
        exit 1
    fi
    log "Upload test success"
    log "$msg"
}

function download_test() {
    log "Test download file"
    msg=$($MC cp store/yd-public/$UPLOAD_TEST_FILE_NAME $DOWNLOAD_TEST_FILE)
    if [ $? != 0 ]; then
        log "Download test fail!"
        log "$msg"
        exit 1
    fi
    log "Download test success"
    log "$msg"
}

function remove_test() {
    log "Test remove file"
    msg=$($MC rm store/yd-public/$UPLOAD_TEST_FILE_NAME)
    if [ $? != 0 ]; then
        log "Remove test fail!"
        log "$msg"
        exit 1
    fi
    log "Remove test success"
    log "$msg"
}

function heal() {
    docker cp $MC $STORE_ID:/
    docker exec -t $STORE_ID /mc config host add store http://localhost:9000 $MC_USER $MC_PASS
    docker exec -t $STORE_ID /mc admin heal -r --json store | tee -a $HEAL_LOG
}

function backup() {
    backup_folder=${1%/}
    if [ ! -d $backup_folder ]; then
        echo "$backup_folder does not exist, create dir $backup_folder"
        mkdir -p $backup_folder
    fi

    mkdir -p $backup_folder/yd-bucket
    mkdir -p $backup_folder/yd-public

    $MC mirror store/yd-bucket $backup_folder/yd-bucket
    yd_public=$($MC ls store | grep "yd-public")
    if [ ! -z "$yd_public" ]; then
        $MC mirror store/yd-public $backup_folder/yd-public
    fi
}

function restore() {
    if [ ! -d $1 ]; then
        echo "$1 does not exist, exist with error"
        exit 1
    fi

    # check if yd-bucket exists
    bucket_exist=$($MC ls store | awk '{if ($5=="yd-bucket/") print 1}')
    if [ "$bucket_exist" == 1 ]; then
        $MC mirror --overwrite $1/yd-bucket store/yd-bucket
    else
        echo "yd-bucket doesn't exist, create bucket... "
        $MC mb store/yd-bucket
        $MC mirror $1/yd-bucket store/yd-bucket
    fi

    # check if yd-public exists
    public_bucket_exist=$($MC ls store | awk '{if ($5=="yd-public/") print 1}')
    if [ "$public_bucket_exist" == 1 ]; then
        $MC mirror --overwrite $1/yd-public store/yd-public
    else
        echo "yd-public doesn't exist, create bucket... "
        $MC mb store/yd-public
        $MC mirror $1/yd-public store/yd-public
    fi

    # grant policy
    yd_bucket_policy_set
    yd_public_policy_set
}

if [ "$1" == "check" ]; then
    check
    exit 0
fi

if [ "$1" == "heal" ]; then
    heal
    exit 0
fi

if [ "$1" == "backup" ]; then
    if [ -z "$2" ]; then
        echo "Please provide backup dir"
        exit 1
    fi
    backup $2
    exit 0
fi

if [ "$1" == "restore" ]; then
    if [ -z "$2" ]; then
        echo "Please provide restore dir"
        exit 1
    fi
    restore $2
    exit 0
fi

echo "Usage: store.sh [check|heal|backup backup_dir|restore restore_dir]"
exit 0
