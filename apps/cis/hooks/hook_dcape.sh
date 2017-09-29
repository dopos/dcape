#!/bin/bash

# This webhook script intended for use inside dcape container
# so in has some noted defaults for it
# But you can change them for your needs.
# See README.md for details.

# ------------------------------------------------------------------------------
# Vars from webhook

MODE=${MODE:-remote}
EVENT=${EVENT:-push}
URL_BRANCH=${URL_BRANCH:-default}
REF=${REF:-refs/heads/master}
REPO_PRIVATE=${REPO_PRIVATE:-false}
SSH_URL=${SSH_URL}
CLONE_URL=${CLONE_URL}

# ------------------------------------------------------------------------------
# Vars from ENV

# dir to place deploys in
#DEPLOY_ROOT

# required secret from hook
#DEPLOY_PASS

# ssh with private key
#GIT_SSH_COMMAND

# Environment vars filename
DEPLOY_CONFIG=${DEPLOY_CONFIG:-.env}
# KV storage key prefix
KV_PREFIX=${KV_PREFIX:-} # "/conf"
# KV storage URI
ENFIST=${ENFIST:-http://enfist:8080/rpc}
# if MODE=local rename git host to this local hostname
LOCAL_GIT_HOST=${LOCAL_GIT_HOST:-gitea}
# App deploy root dir
DEPLOY_PATH=${DEPLOY_PATH:-/$DEPLOY_ROOT/apps}
# Logfiles root dir
DEPLOY_LOG=${DEPLOY_LOG:-/$DEPLOY_ROOT/log/webhook}
# Directory for per project deploy logs
DEPLOY_LOG_DIR=${DEPLOY_LOG_DIR:-$DEPLOY_LOG/deploy}
# Hook logfile
HOOK_LOG=${HOOK_LOG:-$DEPLOY_LOG/webhook.log}
# Git bin used
GIT=${GIT:-git}
# Make bin used
MAKE=${MAKE:-make}
# Tag prefix matched => skip hook run
TAG_PREFIX_SKIP=${TAG_PREFIX_SKIP:-tmp}
# Tag prefix set and does not match => skip hook run
TAG_PREFIX_FILTER=${TAG_PREFIX_FILTER:-}

# ------------------------------------------------------------------------------
# Internal config

# KV-store key to allow this hook
VAR_ENABLED="_CI_HOOK_ENABLED"
_CI_HOOK_ENABLED=no

# make hot update without container restart
VAR_UPDATE_HOT="_CI_HOOK_UPDATE_HOT"
_CI_HOOK_UPDATE_HOT="no"

# make target to start app
VAR_MAKE_START="_CI_MAKE_START"
_CI_MAKE_START=start-hook

VAR_MAKE_UPDATE="_CI_MAKE_UPDATE"
_CI_MAKE_UPDATE="update"

VAR_MAKE_STOP="_CI_MAKE_STOP"
_CI_MAKE_STOP="stop"

# ------------------------------------------------------------------------------

# strict mode http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

# ------------------------------------------------------------------------------
# logging func
log() {
  local dt=$(date "+%F %T")
  echo  "$dt $@"
}

# ------------------------------------------------------------------------------
# prepare deploy.log
deplog_begin() {
  local dest=$1
  shift
  [[ $dest == "-" ]] && return
  local dt=$(date "+%F %T")
  echo "------------------ $dt / $@" >> $dest
}

# ------------------------------------------------------------------------------
# finish deploy.log
deplog_end() {
  local dest=$1
  shift
  [[ $dest == "-" ]] && return
  local dt=$(date "+%F %T")
  echo -e "\n================== $dt" >> $dest
}

# ------------------------------------------------------------------------------
# write line into deploy.log & double it with log()
deplog() {
  local dest=$1
  [[ $dest == "-" ]] && return
  shift
  log $@
  echo $@ >> $dest
}

# ------------------------------------------------------------------------------
# Get value from KV store
kv_read() {
  local path=$1
  local ret=$(curl -gs $ENFIST/tag_vars?a_code=$path | jq -r .result[0].tag_vars)
  [[ "$ret" == "null" ]] && ret=""
  config=$ret
}
# ------------------------------------------------------------------------------
# Get value from KV store
config_var() {
  local config=$1
  local key=$2
  if [[ "$config" ]] ; then
    local row=$(echo "$config" | grep -E "^$key=")
    if [[ "$row" ]] ; then
      echo "${row#*=}"
      return
    fi
  fi
  echo ${!key} # get value from env
}
# ------------------------------------------------------------------------------
# Parse STDIN as JSON and echo "name=value" pairs
kv2vars() {
  local key=$1
  local r=$(curl -gs $ENFIST/tag_vars?a_code=$key)
  #echo "# Generated from KV store $key"
  local ret=$(echo "$r" | jq -r .result[0].tag_vars)
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
  local req=$(curl -gsd "$q" $ENFIST/tag_$cmd)
  # echo $req
}

# ------------------------------------------------------------------------------
# get application deploy dir name from repo and tag
depdir() {
  local repo=$1
  local tag=$2

  # TODO: clone url support

  local r0=${repo#*:}         # remove proto
  local r1=${r0%.git}         # remove suffix

  # TODO: gitea for "create" event sends ssh_url as
  #   git@gitea:/jean/dcape-app-powerdns.git
  # instead
  #   git@gitea:jean/dcape-app-powerdns.git
  r1=${r1#/} # gitea workaround

  local repo_path=${r1/\//--}  # org/project -> org--project
  echo ${repo_path}--${tag}
}

# ------------------------------------------------------------------------------
# KV store key exists: save to $DEPLOY_CONFIG
# or $DEPLOY_CONFIG exists: load it to KV store
# else: generate default $DEPLOY_CONFIG and save it to KV store
env_setup() {
  local config=$1
  local key=$2

  # Get data from KV store
  if [[ "$config" ]] ; then
    log "Save KV $key into $DEPLOY_CONFIG"
    echo "$config" > $DEPLOY_CONFIG
    return
  fi

  if [ -f $DEPLOY_CONFIG ] ; then
    log "Load KV $key from $DEPLOY_CONFIG"
    cat $DEPLOY_CONFIG | vars2kv set $key
    config=$(cat $DEPLOY_CONFIG)
    return
  fi

  log "Load KV $key from default config"
  $MAKE $DEPLOY_CONFIG || true
  log "Default config generated"
  cat $DEPLOY_CONFIG | vars2kv set $key
  local row=$(grep -E "^$VAR_ENABLED=" $DEPLOY_CONFIG)
  [[ "$row" ]] || echo "${VAR_ENABLED}=${_CI_HOOK_ENABLED}" | vars2kv append $key
  local row=$(grep -E "^$VAR_UPDATE_HOT=" $DEPLOY_CONFIG)
  [[ "$row" ]] || echo "${VAR_UPDATE_HOT}=${_CI_HOOK_UPDATE_HOT}" | vars2kv append $key
  log "Prepared default config"
}

# ------------------------------------------------------------------------------
# Run 'make stop' if Makefile exists
make_stop() {
  local path=$1
  local cmd=$2
  if [ -f $path/Makefile ] ; then
    pushd $path > /dev/null
    log "$MAKE $cmd"
    $MAKE $cmd
    popd > /dev/null
  fi
}

# ------------------------------------------------------------------------------
# Check that ENV satisfies conditions
condition_check() {

  if [[ "$DEPLOY_PASS" != "$SECRET" ]] ; then
    log "Hook aborted: password does not match"
    exit 10
  fi

  # repository url
  if [[ "$REPO_PRIVATE" == "true" ]] ; then
    repo=$SSH_URL
  else
    repo=$CLONE_URL
  fi
  if [[ ! "repo" ]] ; then
    log "Hook skipped: repository.{ssh,clone}_url key empty in payload (private:$REPO_PRIVATE)"
    exit 11
  fi

  # TODO: support "tag"
  if [[ "$EVENT" != "push" ]] && [[ "$EVENT" != "create" ]]; then
    log "Hook skipped: only push & create supported, but received '$EVENT'"
    exit 12
  fi


  # tag/branch name
  if [[ $URL_BRANCH != "default" ]] ; then
    tag=$URL_BRANCH
  else
    tag=${REF#refs/heads/}
  fi

  if [[ $tag != ${tag#$TAG_PREFIX_SKIP} ]] ; then
    log "Hook skipped: ($TAG_PREFIX_SKIP) matched"
    exit 13
  fi

  if [[ "$TAG_PREFIX_FILTER" ]] && [[ $tag == ${tag#$TAG_PREFIX_FILTER} ]] ; then
    log "Hook skipped: ($tag) ($TAG_PREFIX_FILTER) does not matched"
    exit 14
  fi

}

# ------------------------------------------------------------------------------

process() {

  local repo
  local tag
  condition_check

  local deploy_dir=$(depdir $repo $tag)

  # dcape on same host
  [[ "$MODE" == "local" ]] && repo=${repo/@*:/@$LOCAL_GIT_HOST:/}

  local config
  kv_read $deploy_dir

  local deploy_key=$KV_PREFIX$deploy_dir
  pushd $DEPLOY_PATH > /dev/null

  # Cleanup old distro
  if [[ ${tag%-rm} != $tag ]] ; then
    local rmtag=${tag%-rm}
    log "$repo $rmtag"
    deploy_dir=$(depdir $repo $rmtag)
    log "Requested cleanup for $deploy_dir"
    if [ -d $deploy_dir ] ; then
      log "Removing $deploy_dir..."
      local make_cmd=$(config_var "$config" $VAR_MAKE_STOP)
      make_stop $deploy_dir $make_cmd
      rm -rf $deploy_dir || { log "rmdir error: $!" ; exit $? ; }
    fi
    log "Cleanup complete"
    exit 0
  fi

  # check if hook is set and disabled
  # continue setup otherwise
  local enabled=$(config_var "$config" $VAR_ENABLED)

  # check only when config loaded
  if [[ "$config" ]] && [[ "$enabled" == "no" ]] ; then
    log "$VAR_ENABLED value disables hook because not equal to 'yes' ($enabled). Exiting"
    exit 15
  fi

  local hot_enabled=$(config_var "$config" $VAR_UPDATE_HOT)

  # deploy per project log directory
  local deplog_dest

  if [ -d $DEPLOY_LOG_DIR ] || mkdir -pm 777 $DEPLOY_LOG_DIR ; then
    deplog_dest="$DEPLOY_LOG_DIR/$deploy_dir.log"
  else
    echo "mkdir $DEPLOY_LOG_DIR error, disable deploy logging"
    deplog_dest="-"
  fi

  if [[ "$hot_enabled" == "yes" ]] && [ -d $deploy_dir ] ; then
    log "Requested hot update for $deploy_dir..."
    pushd $deploy_dir > /dev/null
    if [ -f Makefile ] ; then
      log "Setup hot update.."
      env_setup "$config" $deploy_key
    fi
    local make_cmd=$(config_var "$config" $VAR_MAKE_UPDATE)
    log "Pull..."
    $GIT pull --recurse-submodules 2>&1 || { echo "Pull error: $?" ; exit 1 ; }
    log "Pull submodules..."
    $GIT submodule update --recursive --remote 2>&1 || { echo "sPull error: $?" ; exit 1 ; }
    if [[ "$make_cmd" != "" ]] ; then
      log "Starting $MAKE $make_cmd..."
      deplog_begin $deplog_dest $make_cmd
      # NOTE: This command must start container if it does not running
      $MAKE $make_cmd >> $deplog_dest 2>&1
      deplog_end $deplog_dest
    fi
    popd > /dev/null
    log "Hot update completed"
    return
  fi

  if [ -d $deploy_dir ] ; then
    log "ReCreating $deploy_dir..."
    local make_cmd=$(config_var "$config" $VAR_MAKE_STOP)
    make_stop $deploy_dir $make_cmd
    rm -rf $deploy_dir || { log "rmdir error: $!" ; exit $? ; }
  else
    # git clone will create it if none but we have to check permissions
    log "Creating $deploy_dir..."
    mkdir -p $deploy_dir || { log "mkdir error: $!" ; exit $? ; }
  fi
  log "Clone $repo / $tag..."
  log "git clone --depth=1 --recursive --branch $tag $repo $deploy_dir"
  $GIT clone --depth=1 --recursive --branch $tag $repo $deploy_dir || { echo "Clone error: $?" ; exit 1 ; }
  pushd $deploy_dir > /dev/null

  if [ -f Makefile ] ; then
    log "Setup $deploy_dir..."

    env_setup "$config" $deploy_key

    # check if hook was enabled directly
    if [[ "$enabled" != "yes" ]] ; then
      log "$VAR_ENABLED value disables hook because not equal to 'yes' ($enabled). Exiting"
      popd > /dev/null # deploy_dir
      # Setup loaded in kv and nothing started
      rm -rf $deploy_dir || { log "rmdir error: $!" ; exit $? ; }
      exit 16
    fi
    local make_cmd=$(config_var "$config" $VAR_MAKE_START)
    log "Starting $MAKE $make_cmd..."
    deplog_begin $deplog_dest $make_cmd
    $MAKE $make_cmd >> $deplog_dest 2>&1
    deplog_end $deplog_dest
  fi
  popd > /dev/null # deploy_dir
  popd > /dev/null # DEPLOY_PATH
  log "Deploy completed"
}

process >> $HOOK_LOG 2>&1
