#
# WebHook Continuous Intergation library
#
# ------------------------------------------------------------------------------

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
# Parse STDIN as JSON and echo "name=value" pairs
kv2vars() {
  local key=$1
  echo "# Generated from KV store $key"
  jq -r '.[] | (.Key|ltrimstr("'$key'/")) +"\t"+  .Value ' | while read k v ; do
    val=$(echo -n "$v" | base64 -d)
    if [[ "${val/ /}" != "$val" ]] ; then
      echo "$k=\"$val\""
    else
      echo "$k=$val"
    fi
  done
}

# ------------------------------------------------------------------------------
# Get value from KV store
kv_read() {
  local key=$1
  val=$(curl -s http://localhost:8500/v1/kv/conf/$distro_path/$key | jq -r '.[] | .Value' |  base64 -d)
  echo $val
}

# ------------------------------------------------------------------------------
# Parse STDIN as "name=value" pairs and PUT them into KV store
vars2kv() {
  local key=$1
  while read line ; do
    s=${line%%#*} # remove endline comments
    [ -n "${s##+([[:space:]])}" ] || continue # ignore line if contains only spaces
    name=${s%=*}
    val=$(eval echo ${s#*=})

    #echo "=$name: $val="
    curl -s -X PUT -d "$val" http://localhost:8500/v1/kv/$key/$name > /dev/null || echo "err saving $name"
  done
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
  if [[ "$arg" != "${arg#/}" ]] ; then
    # ARG begins with /
    r0=${arg#/}
  else
    [[ "$arg" ]] || arg=default
    r0=$repo_path/$tag/$arg
  fi
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
  local kv=$(curl -s http://localhost:8500/v1/kv/$key?recurse)

  if [[ ! "$kv" ]] ; then
    if [ ! -f $config ] ; then
      make setup
      log "Load KV $key from default $config"
      cat $config | vars2kv $key
      echo "${VAR_ENABLED}=${_CI_HOOK_ENABLED}" | vars2kv $key
      echo "${VAR_MAKE_START}=${_CI_MAKE_START}" | vars2kv $key

      echo "${VAR_UPDATE_HOT}=${_CI_HOOK_UPDATE_HOT}" | vars2kv $key
      echo "${VAR_MAKE_UPDATE}=\"${_CI_MAKE_UPDATE}\"" | vars2kv $key

      log "Prepared default config. Exiting"
      exit 0
    fi
    log "Load KV $key from $config"
    cat $config | vars2kv $key
  else
    log "Save KV $key into $config"
    echo $kv | kv2vars $key > $config
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

integrate() {

  local event=$1
  local is_consup=$2

  # Docker ENVs
  # DISTRO_ROOT - git clone into /home/app/ci/$DISTRO_ROOT
  # DISTRO_CONFIG - file to save app config
  # SSH_KEY_NAME - ssh priv key in /home/app

  # All json payload
  # echo "${HOOK_}" | jq '.'

  # repository url
  local repo=$(echo "${HOOK_}" | jq -r '.repository.ssh_url')

  # event type ("tag" etc)
  local op=$(echo "${HOOK_}" | jq -r '.ref_type')
  [[ "$op" == "null" ]] && op="tag"

  if [[ "$event" != "push" && "$event" != "create" ]] || [[ "$op" != "tag" ]] ; then
    log "Hook skipped - no event"
    exit 0
  fi

  # tag/branch name
  if [[ $HOOK_tag != "-" ]] ; then
    local tag=$HOOK_tag
  else
    local tag=$(echo "${HOOK_}" | jq -r '.ref')
    tag=${tag#refs/heads/}
  fi
  local distro_path=$(mkroot $repo $tag ${HOOK_config})

  # consup domain on same host
  [[ "$is_consup" == "true" ]] && repo=${repo/:/.web.service.consul:/}

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
      rm -rfd $path || { log "rmdir error: $!" ; exit $? ; }
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
  local deplog_root="/home/app/log/deploy"
  [ -d $deplog_root ] || mkdir -pm 777 $deplog_root || { echo "mkdir error, disable deploy logging" && deplog_root="" ; }
  local deplog_dest="$deplog_root/$distro_path.log"

  if [[ "$hot_enabled" == "yes" ]] ; then
    log "Requested hot update for $path..."
    [ -d $DISTRO_ROOT/$distro_path ] || { log "Dir $distro_path does not exists. Exiting" ; exit 1 ; }
    pushd $DISTRO_ROOT/$distro_path
    if [ -f Makefile ] ; then
      log "Setup $distro_path"
      setup_config conf/$distro_path $DISTRO_CONFIG
    fi
    local hot_cmd=$(kv_read $VAR_MAKE_UPDATE)
    log "Pull..."
    . /home/app/git.sh -i /home/app/$SSH_KEY_NAME pull --recurse-submodules 2>&1 || { echo "Pull error: $?" ; exit 1 ; }
    log "Pull submodules..."
    . /home/app/git.sh -i /home/app/$SSH_KEY_NAME submodule update --recursive --remote 2>&1 || { echo "sPull error: $?" ; exit 1 ; }
    if [[ "$hot_cmd" != "" ]] ; then
      log "Run update cmd ($hot_cmd)..."
      deplog_begin $deplog_dest "update"
      deplog $deplog_dest "APP_ROOT=$host_root/$DISTRO_ROOT APP_PATH=$distro_path make $hot_cmd"
      # NOTE: This command must start container if it does not running
      APP_ROOT=$host_root/$DISTRO_ROOT APP_PATH=$distro_path make $hot_cmd >> $deplog_dest 2>&1
      deplog_end $deplog_dest
    fi
    popd > /dev/null
    log "Hook stop"
    return
  fi

  if [ -d $path ] ; then
    log "ReCreating $path..."
    make_stop $path
    rm -rfd $path || { log "rmdir error: $!" ; exit $? ; }
  else
    log "Creating $path..."
    mkdir -p $path || { log "mkdir error: $!" ; exit $? ; }
  fi
  pushd $DISTRO_ROOT
    log "Clone $repo / $tag..."

    log bash /home/app/git.sh -i /home/app/$SSH_KEY_NAME clone --depth=1 --recursive --branch $tag $repo $distro_path
    . /home/app/git.sh -i /home/app/$SSH_KEY_NAME clone --depth=1 --recursive --branch $tag $repo $distro_path || { echo "Clone error: $?" ; exit 1 ; }
  pushd $distro_path

  if [ -f Makefile ] ; then
    log "Setup $distro_path"

    setup_config conf/$distro_path $DISTRO_CONFIG

    # check if hook was enabled directly
    if [[ "$enabled" != "yes" ]] ; then
      log "$VAR_ENABLED value disables hook because not equal to 'yes' ($enabled). Exiting"
      exit 2
    fi

    # APP_ROOT - hosted application dirname for mount /home/app and /var/log/supervisor
    local host_root=$(host_home_app)
    deplog_begin $deplog_dest "create"
    deplog $deplog_dest APP_ROOT=$host_root/$DISTRO_ROOT APP_PATH=$distro_path make ${_CI_MAKE_START}
    APP_ROOT=$host_root/$DISTRO_ROOT APP_PATH=$distro_path make ${_CI_MAKE_START} >> $deplog_dest 2>&1
    deplog_end $deplog_dest
  fi
  popd > /dev/null
  popd > /dev/null
  log "Hook stop"

}
