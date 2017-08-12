#!/bin/bash
# ------------------------------------------------------------------------------
# setup-remote-host.sh
# Setup remote ubuntu/debian host from scratch
# This script is a part of DCAPE project
# See https://github.com/TenderPro/dcape
# ------------------------------------------------------------------------------

# default user login
admin=op

# ------------------------------------------------------------------------------
help() {

cat <<EOF

setup-remote-host.sh - Remote Server Setup Script

Usage:

  ./setup-remote-host.sh HOST [OPTIONS]

Where HOST is remote server hostname or ip
  and OPTIONS are:

  -a USER, --admin USER - create & setup user USER for remote login (default: $admin, set '-' to disable)
  -d, --docker          - install docker
  -e, --extended        - install extended package set (mc wget make sudo ntpdate)
  -h, --help            - show this help
  -k FILE, --key: FILE  - ssh-copy-id FILE to remote user 
  -l, --locale          - setup local server locale at remote server
  -n, --ntpdate         - setup ntpdate cron job
  -p NN, --port NN      - change ssh service port to NN
  -s SIZE, --swap SIZE  - create swap volume size SIZE
  -t, --tune            - tune sysctl for virtual server
  -u, --update          - update system packages

EXAMPLE:

  bash setup-remote-host.sh 127.0.0.1 -a op -p 32 -s 1Gb -delntu

SEE ALSO:

  * https://github.com/TenderPro/dcape

EOF

# TODO: -c ARGS, --cape ARGS  - install dcape with init args ARGS        

}

host=$1
shift
# ------------------------------------------------------------------------------

# arg parsing based on https://stackoverflow.com/a/14787208

args=$(getopt -l "admin:,docker,extended,key:,locale,ntpdate,port:,swap:,tune,update" -o "a:dek:lnp:s:tu" -- "$@")

eval set -- "$args"

while [ $# -ge 1 ]; do
  case "$1" in
    --)
      # No more options left.
      shift
      break
     ;;
    -a|--admin)
      admin="$2" ; shift ;;
    -d|--docker)
      docker="yes" ;;
    -e|--extended)
      extended="yes" ;;
    -k|--key)
      key="$2" ; shift ;;
    -l|--locale)
      locale="yes" ;;
    -n|--ntpdate)
      ntpdate="yes" ;;
    -p|--port)
      port="$2" ; shift ;;
    -s|--swap)
      swap="$2" ; shift ;;
    -t|--tune)
      tune="yes" ;;
    -u|--update)
      update="yes" ;;
    *)
      help ;;
  esac

  shift
done

if [[ ! "$host" ]] ; then
  echo "Error: HOST is required. Aborting"
  help
  exit 1
elif [[ "$host" == "-h" || "$host" == "--help" ]] ; then
  help
  exit 1
fi

[[ "$admin" == "-" ]] && admin=

# ------------------------------------------------------------------------------

cat <<EOF
** setup-remote-host.sh options:

host:     $host

admin:    ${admin:--}
key:      ${key:--}
port:     ${port:--}
swap:     ${swap:--}
docker:   ${docker:--}
extended: $extended
locale:   $locale
ntpdate:  $ntpdate
tune:     $tune
update:   $update
EOF

read -p "[Hit Enter to continue]" X

# ------------------------------------------------------------------------------
echo -n "* ssh keyfile: "
if [[ "$key" ]] ; then
  echo "copying..."
  ssh-copy-id -i $key root@$host
  echo "Done"
else
  echo "skip"
fi

echo "** Run remote setup at host $host..."
ssh root@$host 'bash -s' << EOF

# stop on error
set -e

# ------------------------------------------------------------------------------
echo -n "* swapfile: "
if [[ "$swap" ]] ; then
  # https://www.digitalocean.com/community/tutorials/how-to-add-swap-on-ubuntu-14-04
  swap_file=/swapfile
  if [ -f \$swap_file ] ; then
    echo "Already exists"
  else
    echo -n "Enabling $swap..."
    fallocate -l $swap \$swap_file
    chmod 600 \$swap_file
    mkswap \$swap_file
    swapon \$swap_file
    echo "\$Sswap_file   none    swap    sw    0   0" >> /etc/fstab
    echo "Ok"
  fi
else
  echo "skip"
fi

# ------------------------------------------------------------------------------
echo -n "* server tune: "
if [[ "$tune" ]] ; then
  echo -n "setup..."
  grep vm.swappiness /etc/sysctl.conf || {
    echo "vm.swappiness=10" >> /etc/sysctl.conf
    sysctl vm.swappiness=10
  }

  grep vfs_cache_pressure /etc/sysctl.conf || {
    echo "vfs_cache_pressure=50" >> /etc/sysctl.conf
    sysctl vm.vfs_cache_pressure=50
  }
  echo "Ok"
else
  echo "skip"
fi

# ------------------------------------------------------------------------------
echo -n "* locale: "
if [[ "$locale" ]] ; then
  echo -n "setup $LC_NAME..."
  locale-gen $LC_NAME
  echo "Ok"
else
  echo "skip"
fi

export DEBIAN_FRONTEND=noninteractive

# ------------------------------------------------------------------------------
echo -n "* update: "
if [[ "$update" ]] ; then
  echo -n "run..."
  apt update
  apt -y upgrade
  echo "Ok"
else
  echo "skip"
fi

# ------------------------------------------------------------------------------
echo -n "* extended packages: "
if [[ "$extended" ]] ; then
  echo -n "install..."
  apt-get -y remove apache2 python-samba samba-common
  apt-get -y install mc wget make sudo ntpdate
  echo "Ok"
else
  echo "skip"
fi

# ------------------------------------------------------------------------------
echo -n "* ntpdate: "
if [[ "$ntpdate" ]] ; then
  echo -n "setup..."
  which ntpdate || apt-get -y install ntpdate
  echo "#!/bin/sh" > /etc/cron.daily/ntpdate
  echo "ntpdate -u ntp.ubuntu.com pool.ntp.org" >> /etc/cron.daily/ntpdate
  chmod a+x /etc/cron.daily/ntpdate
  echo "Ok"
else
  echo "skip"
fi

# ------------------------------------------------------------------------------
echo -n "* docker: "
if [[ "$docker" ]] ; then
  echo -n "install..."
  which docker > /dev/null || wget -qO- https://get.docker.com/ | sh
  echo "Ok"
else
  echo "skip"
fi

# ------------------------------------------------------------------------------
echo -n "* admin: "
if [[ "$admin" ]] ; then
  echo -n "setup user $admin..."
  NEWUSER=$admin
  HOMEROOT=/home
  HOMEDIR=\$HOMEROOT/\$NEWUSER
  [ -d \$HOMEROOT ] || mkdir \$HOMEROOT

  # Check if user exists already
  grep -qe "^\$NEWUSER:" /etc/passwd || useradd -d \$HOMEDIR -m -r -s /bin/bash -Gwww-data -gusers -gdocker \$NEWUSER
  [ -d \$HOMEDIR/.ssh ] || sudo -u \$NEWUSER mkdir -m 700 \$HOMEDIR/.ssh

  KEYFILE=\$HOMEDIR/.ssh/authorized_keys
  if [ ! -f \$KEYFILE ] ; then
    cp /root/.ssh/authorized_keys \$KEYFILE
    chown \$NEWUSER \$KEYFILE
    chmod 600 \$KEYFILE
  fi

  # allow sudo without pass
  [ -f /etc/sudoers.d/\$NEWUSER ] || {
    echo "\$NEWUSER ALL=NOPASSWD:ALL" > /etc/sudoers.d/\$NEWUSER
    chmod 440 /etc/sudoers.d/\$NEWUSER
  }
  echo "Ok"
else
  echo "skip"
fi

# ------------------------------------------------------------------------------
echo -n "* sshd: "
if [[ "$port" ]] ; then
  echo -n "setup ssh with port $port..."

  # TODO
  sed -i "/^Port 22/c Port \$port" /etc/ssh/sshd_config

  if [[ "$admin" ]] ; then
    echo -n "switch user..."
    # Deny root login via ssh
    sed -i "/^PermitRootLogin.*/c PermitRootLogin no" /etc/ssh/sshd_config

    # Deny password login
    sed -i "/#PasswordAuthentication *yes/c PasswordAuthentication no" /etc/ssh/sshd_config
  fi

  #service ssh reload
  echo "Ok"
else
  echo "skip"
fi
EOF
# ------------------------------------------------------------------------------
echo "** Server setup complete"
