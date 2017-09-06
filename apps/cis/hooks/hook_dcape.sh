#!/bin/bash

# This script called by webhook
# See hooks.json

# ------------------------------------------------------------------------------

  # Docker ENVs
  # DISTRO_ROOT - git clone into /home/app/ci/$DISTRO_ROOT
  # DISTRO_CONFIG - file to save app config
  # SSH_KEY_NAME - ssh priv key in /home/app

#DISTRO_ROOT=/data/apps
#DISTRO_CONFIG=.env
#SSH_KEY_NAME=hook
#HOOK_MODE=local
#HOOK_URL_BRANCH=any

#HOOK_PAYLOAD={json}
# vars from hook uri args
[[ "$HOOK_config" ]] || HOOK_config=default
[[ "$HOOK_tag" ]] || HOOK_tag="-"

# KV-store key to allow this hook
_CI_HOOK_ENABLED=no
VAR_ENABLED="_CI_HOOK_ENABLED"

# make target to start app
VAR_MAKE_START="_CI_MAKE_START"
_CI_MAKE_START=start-hook

# make hot update without container restart
VAR_UPDATE_HOT="_CI_HOOK_UPDATE_HOT"
VAR_MAKE_UPDATE="_CI_MAKE_UPDATE"
_CI_HOOK_UPDATE_HOT="no"
_CI_MAKE_UPDATE="update"

KV_PREFIX="" # "/conf"
ENFIST=${ENFIST:-http://enfist:8080/rpc}

# ------------------------------------------------------------------------------

# strict mode http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

# ------------------------------------------------------------------------------
# logging func
log() {
  local dt=$(date "+%F %T")
  echo  "$dt $1"
}

# ------------------------------------------------------------------------------
# prepare deploy.log
deplog_begin() {
  local dest=$1
  shift
  local dt=$(date "+%F %T")
  echo "------------------ $dt / $@" >> $dest
}

# ------------------------------------------------------------------------------
# finish deploy.log
deplog_end() {
  local dest=$1
  shift
  local dt=$(date "+%F %T")
  echo "================== $dt" >> $dest
}

# ------------------------------------------------------------------------------
# write line into deploy.log & double it with log()
deplog() {
  local dest=$1
  shift
  log $@
  echo $@ >> $dest
}

# ------------------------------------------------------------------------------
# Get value from KV store
kv_read() {
  local key=$1
  local r=$(curl -gs $ENFIST/tag_vars?a_code=$distro_path)
  local vars=$(echo "$r" | jq -r .result[0].tag_vars)
#  local vars=$(echo "$r" | jq -r .result[0].tag_vars | sed 's/\\n/\n/g')
  if [[ "$vars" != "null" ]] ; then
    local row=$(echo "$vars" | grep -E "^$key=")
    echo "${row#*=}"
  fi
}
# ------------------------------------------------------------------------------
# Parse STDIN as JSON and echo "name=value" pairs
kv2vars() {
  local key=$1
>&2 echo "-----kv2vars: $ENFIST/tag_vars?a_code=$key"
  local r=$(curl -gs $ENFIST/tag_vars?a_code=$key)
  #echo "# Generated from KV store $key"
  local ret=$(echo "$r" | jq -r .result[0].tag_vars)
#  local ret=$(echo "$r" | jq -r .result[0].tag_vars | sed 's/\\n/\n/g')
>&2 echo "-----kv2vars ret:$ret" 
  [[ "$ret" == "null" ]] && ret="" 
  echo "$ret"
}

# ------------------------------------------------------------------------------
# Parse STDIN as "name=value" pairs and PUT them into KV store
vars2kv() {
  local cmd=$1
  local key=$2
  local q=$(jq -R -sc ". | {\"a_code\":\"$key\",\"a_data\":.}")
  # pack newlines, escape doble quotes
#  local c=$(sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\n/g' | sed 's/"/\\"/g')
#  local q='{"a_code":"'$key'","a_data":"'$c'"}'
>&2 echo "-----vars2kv: $q $ENFIST/tag_$cmd"
  local req=$(curl -gsd "$q" $ENFIST/tag_$cmd)
}

# ------------------------------------------------------------------------------
# get application root from repo, tag and optional arg
# use only arg (withour repo and tag) if arg begins with "/"
# use "default" as arg value if it empty
mkroot() {
  local repo=$1
  local tag=$2
  local arg=$3

  local r0=${repo#*:}         # remove proto
  local repo_path=${r0%.git}  # remove suffix
  local res=""
  r0=$repo_path/$tag
  echo ${r0//\//--}
}

# ------------------------------------------------------------------------------
# Use .config if exists
# or load .config from KV store if key exists
# or generate default .config and save it to KV store
setup_config() {
  local key=$1
  local config=$2
  [[ "$config" ]] || config=.config

  # Get data from KV store
  local kv=$(kv2vars $key)
>&2 echo -e "-----------\n$kv\n-----------\n"

  if [[ ! "$kv" ]] ; then
    if [ ! -f $config ] ; then
      make $config
      log "Load KV $key from default $config"
      cat $config | vars2kv set $key
      cat | vars2kv append $key <<EOF
${VAR_ENABLED}=${_CI_HOOK_ENABLED}
${VAR_MAKE_START}=${_CI_MAKE_START}

${VAR_UPDATE_HOT}=${_CI_HOOK_UPDATE_HOT}
${VAR_MAKE_UPDATE}=${_CI_MAKE_UPDATE}
EOF
      log "Prepared default config. Exiting"
      exit 0
    fi
    log "Load KV $key from $config"
    cat $config | vars2kv set $key
  else
    log "Save KV $key into $config"
    echo "$kv" > $config
  fi

  . $config

}
# setup_config tests:
# all empty - default .config generated & saved to KV
# only KV - .config loaded from KV
# only .config - .config saved to KV
# both exists - .config updated from KV

# ------------------------------------------------------------------------------
# get host path for /home/app
host_home_app() {
#echo "/opt/srv/ci"
  # get webhook container id
  local container_id=$(cat /proc/self/cgroup | grep "cpuset:/" | sed 's/\([0-9]\):cpuset:\/docker\///g') # '
  # get host path for /home/app
  docker inspect $container_id | jq -r '.[0].Mounts[] | if .Destination == "/home/app" then .Source else empty end'
}

# ------------------------------------------------------------------------------
# Run 'make stop' if Makefile exists
make_stop() {
  local path=$1
  if [ -f $path/Makefile ] ; then
    pushd $path
    log "make stop"
    make stop
    popd
  fi
}

# ------------------------------------------------------------------------------

process() {
  local event=$1

  which curl > /dev/null || apk --update add curl curl-dev
  which make > /dev/null || apk --update add make

  # All json payload
  # echo "${HOOK_}" | jq '.'

  if [[ "$event" != "push" ]] ; then
    log "Hook skipped - only push supported, but received '$event'"
    exit 0
  fi

  local home=$PWD

  # repository url
  local repo=$(echo "${HOOK_PAYLOAD}" | jq -r '.repository.ssh_url')
  if [[ ! "repo" ]] ; then
    log "Hook skipped - repository.ssh_url empty in payload"
    exit 0
  fi


  # tag/branch name
  if [[ $HOOK_URL_BRANCH != "any" ]] ; then
    local tag=$HOOK_URL_BRANCH
  else
    local tag=$(echo "${HOOK_PAYLOAD}" | jq -r '.ref')
    tag=${tag#refs/heads/}
  fi
  local distro_path=$(mkroot $repo $tag ${HOOK_config})

  # consup domain on same host
  [[ "$HOOK_MODE" == "local" ]] && repo=${repo/@*:/@gitea:/}

  local path=$DISTRO_ROOT/$distro_path

  # Cleanup old distro
  if [[ ${tag%-rm} != $tag ]] ; then
    local rmtag=${tag%-rm}
    distro_path=$(mkroot $repo $rmtag ${HOOK_config})

    log "Requested cleanup for $distro_path"
    path=$DISTRO_ROOT/$distro_path
    if [ -d $path ] ; then
      log "Removing $distro_path..."
      make_stop $path
      rm -rf $path || { log "rmdir error: $!" ; exit $? ; }
    fi
    log "Hook cleanup complete"
    exit 0
  fi

  # check if hook is set and disabled
  # continue setup otherwise
  local enabled=$(kv_read $VAR_ENABLED)
  if [[ "$enabled" == "no" ]] ; then
    log "$VAR_ENABLED value disables hook because not equal to 'yes' ($enabled). Exiting"
    exit 1
  fi

  local hot_enabled=$(kv_read $VAR_UPDATE_HOT)

  local host_root=$(host_home_app)

  # deploy log directory
  [ -d $deplog_root ] || mkdir -pm 777 $deplog_root || { echo "mkdir error, disable deploy logging" && deplog_root="" ; }
  local deplog_dest="$deplog_root/$distro_path.log"

  if [[ "$hot_enabled" == "yes" ]] ; then
    log "Requested hot update for $path..."
    [ -d $DISTRO_ROOT/$distro_path ] || { log "Dir $distro_path does not exists. Exiting" ; exit 1 ; }
    pushd $DISTRO_ROOT/$distro_path
    if [ -f Makefile ] ; then
      log "Setup $distro_path for hot update"
      setup_config $KV_PREFIX$distro_path $DISTRO_CONFIG
    fi
    local make_cmd=$(kv_read $VAR_MAKE_UPDATE)
    log "Pull..."
    . $home/git.sh -i $home/$SSH_KEY_NAME pull --recurse-submodules 2>&1 || { echo "Pull error: $?" ; exit 1 ; }
    log "Pull submodules..."
    . $home/git.sh -i $home/$SSH_KEY_NAME submodule update --recursive --remote 2>&1 || { echo "sPull error: $?" ; exit 1 ; }
    if [[ "$make_cmd" != "" ]] ; then
      log "Run update cmd ($make_cmd)..."
      deplog_begin $deplog_dest "update"
      deplog $deplog_dest "APP_ROOT=$host_root$DISTRO_ROOT APP_PATH=$distro_path make $make_cmd"
      # NOTE: This command must start container if it does not running
      APP_ROOT=$host_root$DISTRO_ROOT APP_PATH=$distro_path DOCKER_BIN=vdocker \
        make $make_cmd >> $deplog_dest 2>&1

      deplog_end $deplog_dest
    fi
    popd > /dev/null
    log "Hook stop"
    return
  fi

  if [ -d $path ] ; then
    log "ReCreating $path..."
    make_stop $path
    rm -rf $path || { log "rmdir error: $!" ; exit $? ; }
  else
    log "Creating $path..."
    mkdir -p $path || { log "mkdir error: $!" ; exit $? ; }
  fi
  pushd $DISTRO_ROOT
    log "Clone $repo / $tag..."

    log bash $home/git.sh -i $home/$SSH_KEY_NAME clone --depth=1 --recursive --branch $tag $repo $distro_path
    . $home/git.sh -i $home/$SSH_KEY_NAME clone --depth=1 --recursive --branch $tag $repo $distro_path || { echo "Clone error: $?" ; exit 1 ; }
  pushd $distro_path

  if [ -f Makefile ] ; then
    log "Setup $distro_path"

    setup_config $KV_PREFIX$distro_path $DISTRO_CONFIG

    # check if hook was enabled directly
    if [[ "$enabled" != "yes" ]] ; then
      log "$VAR_ENABLED value disables hook because not equal to 'yes' ($enabled). Exiting"
      exit 2
    fi

    # APP_ROOT - hosted application dirname for mount /home/app and /var/log/supervisor
    local host_root=$(host_home_app)
    local make_cmd=$(kv_read $VAR_MAKE_START)

    deplog_begin $deplog_dest "create"
    deplog $deplog_dest APP_ROOT=$host_root$DISTRO_ROOT APP_PATH=$distro_path make $make_cmd
    APP_ROOT=$host_root$DISTRO_ROOT APP_PATH=$distro_path DOCKER_BIN=vdocker \
      make $make_cmd >> $deplog_dest 2>&1

    deplog_end $deplog_dest
  fi
  popd > /dev/null
  popd > /dev/null
  log "Hook stop"


}

deplog_root="/opt/dcape/var/log/webhook/deploy"

process $@ >> /opt/dcape/var/log/webhook/webhook.log 2>&1
#>/data/log/webhook.err

