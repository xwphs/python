#!/bin/bash

################################################################
# Utilities
################################################################
function good_news() {
    echo -e "\033[1;32m""$@""\033[0m"
}

function info() {
    echo -e "\033[1;34m""$@""\033[0m"
}

function info_title() {
    echo -e "\033[1;34m""$1""\033[0m" | tee -a $2
}

function warn() {
    echo -e "\033[1;33m""[WARN] $@""\033[0m"
}

function error() {
    echo -e "\033[1;31m""[ERROR] $@""\033[0m"
    # DON'T exit, just return 1
    return 1
}

function check_err() {
    RET=$?
    if [ "$RET" != "0" ]; then
        error "$@"
    fi
    return $RET
}

function get_yn_choice() {
    choice=
    while [ "${choice}" != "y" ] && [ "${choice}" != "n" ]; do
        read -r -p "$1 (y/n)" choice </dev/tty
    done
    echo "$choice"
}

# Usage: trim_string "   example   string    "
function trim_string() {
    : "${1#"${1%%[![:space:]]*}"}"
    : "${_%"${_##*[![:space:]]}"}"
    # printf '%s\n' "$_"
    echo $1
}

# Usage: rstrip "string" "pattern"
function rstrip() {
    echo "${1%%$2}"
}

################################################################
# Initialize
################################################################
DOCKER=$(command -v docker)
check_err "Docker not found."

[ ! -z "$DOCKER" ]
check_err "Docker variable not set."

$DOCKER version >/dev/null 2>&1
check_err "Cannot connect to docker daemon."

$DOCKER node ls >/dev/null 2>&1
check_err "This is not swarm manager node."

# the below [grep "y]" is a little tricky, if there is another stack whose name includes a "y", it doesn't work!
STACK=$($DOCKER stack ls --format "{{.Name}}" | grep "y")
check_err "Failed to get stacks."

SCP=$(command -v scp)
check_err "SCP not found."

CURL=$(command -v curl)
check_err "Curl not found."

PYTHON=$(command -v python)
check_err "Python not found."
