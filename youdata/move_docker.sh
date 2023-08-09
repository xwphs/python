#!/usr/bin/env bash

################################################################
# Utilities
################################################################
function good_news {
  echo -e "\033[1;32m""$@""\033[0m"
}

function info {
  echo -e "\033[1;34m""$@""\033[0m" >&2
}

function warn {
  echo -e "\033[1;33m""$@""\033[0m" >&2
}

function fatal {
  echo -e "\033[1;31m""$@""\033[0m" >&2
  exit 1
}

function check_warn {
  RET=$?
  if [ "$RET" != "0" ]; then
    warn "$@"
  fi
  return $RET
}

function check_err {
  RET=$?
  if [ "$RET" != "0" ]; then
    fatal "$@"
  fi
  return $RET
}

function get_yn_choice {
  choice=
  while [ "${choice}" != "y" ] && [ "${choice}" != "n" ]; do
    read -r -p "$1 (y/n)" choice < /dev/tty
  done
  echo "$choice"
}

function real_path {
  RP=$(command -v realpath)
  if [ "$?" = "0" ]; then
    "$RP" -s "$1"
  else
    BASE=$(cd $(dirname "$1") && pwd)
    NAME=$(basename "$1")
    if [ "$BASE" = "/" ]; then
      echo "/$NAME"
    else
      echo "$BASE/$NAME"
    fi
  fi
}

function get_docker_partition {
  df /var/lib/docker | tail -n+2 | awk '{print $1;}'
}

function get_max_avail_partition {
  df | tail -n+2 | awk '{print $1 " " $4 " " $6}' | grep "^\/dev" | sort -r -k 2 -n - | head -n 1
}

function append_docker {
  read P
  if [ "$P" = "" ]; then
    fatal "Invalid path to append docker."
  fi
  if [ "$P" = "/" ]; then
    echo "/docker"
  else
    echo "$P/docker"
  fi
}

################################################################
# Initialize
################################################################
OLD_PART=$(get_docker_partition)
check_err "Failed to get docker partition."
[ ! -z "$OLD_PART" ]
check_err "Failed to set OLD_PART environment variable."

OLD_PATH=$(real_path "/var/lib/docker")
check_err "Failed to get docker folder's real path."
[ ! -z "$OLD_PATH" ]
check_err "Failed to set OLD_PATH environment variable."

NEW_TEMP=$(get_max_avail_partition)
check_err "Failed to get max available space partition info."

NEW_PART=$(echo "$NEW_TEMP" | awk '{print $1;}')
[ ! -z "$NEW_PART" ]
check_err "Failed to get target partition."

NEW_PATH=$(echo "$NEW_TEMP" | awk '{print $3;}' | append_docker)
[ ! -z "$NEW_PATH" ]
check_err "Failed to get target path."

################################################################
# Entrance
################################################################
if [ "$OLD_PART" = "$NEW_PART" ]; then
  good_news "Docker is already in the right partition. :)"
  exit 0
fi

info "Start moving docker to partition ($NEW_PART) on path: $NEW_PATH"
choice=$(get_yn_choice "Do you want to continue?")
if [ "$choice" = "n" ]; then
  exit 1
fi

if [ -e "$NEW_PATH" ]; then
  warn "Already existed on target path: $NEW_PATH"
  info "Making some backups..."
  sudo mv "$NEW_PATH" "${NEW_PATH}.bak"
  check_err "Failed to backup target path: $NEW_PATH"
fi

info "Stopping docker daemon..."
sudo systemctl stop docker
check_err "Failed to stop docker daemon."

info "Moving docker folder..."
sudo mv /var/lib/docker "$NEW_PATH"
check_err "Failed to move docker folder."

info "Making symbolic link..."
sudo ln -s "$NEW_PATH" /var/lib/docker
check_err "Failed to make symbolic link."

info "Starting docker daemon..."
sudo systemctl start docker
check_err "Failed to start docker daemon."

good_news "Docker folder is successfully moved to the max available space partition."
