# dcape Makefile
SHELL             = /bin/bash
CFG               = .env

#- ******************************************************************************
#- DCAPE: general config

#- Enable local gitea on this host: [yes]|<URL>
#- <URL> - external gitea URL
GITEA            ?= yes

#- Enable powerdns on this host: [no]|yes|wild
#- yes - just setup and start
#- wild - use as wildcard domain nameserver
DNS              ?= no

#- Enable Let's Encrypt certificates: [no]|http|wild
#- http - use individual host cert
#- wild - use wildcard domain for DCAPE_DOMAIN
ACME             ?= no

#- container name prefix
DCAPE_TAG        ?= dcape

#- dcape containers hostname domain
DCAPE_DOMAIN     ?= dev.lan

#- ------------------------------------------------------------------------------
#- DCAPE: internal config

#- docker network name
DCAPE_NET        ?= $(DCAPE_TAG)
#- docker internal network name
DCAPE_NET_INTRA  ?= $(DCAPE_TAG)_intra
#- container(s) required for up in any case
#- used in make only
APPS             ?=
#- create db cluster with this timezone
#- (also used by containers)
TZ               ?= $(shell cat /etc/timezone)
#- docker network subnet
DCAPE_SUBNET     ?= 100.127.0.0/24
#- docker intra network subnet
DCAPE_SUBNET_INTRA ?= 100.127.255.0/24
#- Deployment persistent storage, relative
DCAPE_VAR        ?= var

#- Dcape root
DCAPE_ROOT       ?= $(PWD)

ENFIST_URL       ?= http://enfist:8080/rpc
APPS_SYS         ?= db
APPS_ALWAYS      ?= db traefik narra enfist cicd portainer

CFG_BAK          ?= $(CFG).bak
DCINC             = docker-compose.inc.yml
DCINC_CORE        = apps/core/docker-compose.inc.yml
MK_CORE           = apps/core/Makefile.inc

PG_CONTAINER     ?= $(DCAPE_TAG)-db-1

# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------

# if exists - load old values
-include $(CFG_BAK)
export

-include $(CFG)
export

.PHONY: init apply up reup down install dc-dc docker-wait db-create db-drop psql psql-local gitea-setup env-ls env-get env-set help

all: help

# ------------------------------------------------------------------------------
define CONFIG_DEF
# ******************************************************************************
# dcape extra config

# Dcape service apps
#APPS=$(APPS)

# Gitea host for auth
AUTH_SERVER=$(AUTH_SERVER)

# http if ACME=no, https otherwise
DCAPE_SCHEME=$(DCAPE_SCHEME)
endef
export CONFIG_DEF


ifndef APPS
  ifneq ($(DNS),no)
    APPS += powerdns
  endif


  ifeq ($(GITEA),yes)
    APPS += gitea
    AUTH_SERVER ?= $(DCAPE_SCHEME)://$(GITEA_HOST)
  else
    AUTH_SERVER ?= $(GITEA)
  endif
  APPS += $(APPS_ALWAYS)
endif

ifeq ($(ACME),no)
DCAPE_SCHEME ?= http
else
DCAPE_SCHEME ?= https
endif


## make a list $APP -> apps/$APP/$(DCINC)
DCFILESP = $(addprefix apps/,$(APPS))
DCFILES = $(addsuffix /$(DCINC),$(DCFILESP))
MKFILES = $(addsuffix /Makefile.inc,$(DCFILESP))

DC_ARG_SRC = $(addprefix -f ,$(DCINC_CORE) $(DCFILES))

include $(MK_CORE)
include $(MKFILES)
#apps/*/Makefile.inc

# ------------------------------------------------------------------------------
## Docker-compose commands
#:

## (re)start container(s)
u: CMD=up -d $(APPS_SYS) $(shell echo $(APPS))
u: dc-dc

## stop (and remove) container(s)
d: CMD=down
d: dc-dc

## restart container(s)
ru: CMD=up --force-recreate -d $(APPS_SYS) $(shell echo $(APPS))
ru: dc-dc

dc-dc:
	@echo "Running dc command: $(CMD)"
	@echo "Dcape URL: $(DCAPE_SCHEME)://$(DCAPE_HOST)"
	@echo "------------------------------------------"
	@docker compose $(DC_ARG_SRC) \
	  -p $$DCAPE_TAG --project-directory $$PWD \
	  $(CMD)

# ------------------------------------------------------------------------------
## dcape Setup
#:

# create docker-compose image
compose:
	docker build -t ${DCAPE_TAG}-compose --build-arg DRONE_ROOT=${PWD}/apps/core  ./apps/core

## Initially create $(CFG) file with defaults
init: $(DCAPE_VAR)
	@echo "*** $@ $(APPS) ***"
	@$(MAKE) -s config-if
	@for f in $(shell echo $(APPS)) ; do echo $$f ; $(MAKE) -s $${f}-init ; done

$(DCAPE_VAR):
	@mkdir -p $(DCAPE_VAR)

## Apply config to app files & db
apply:
	@echo "*** $@ $(APPS) ***"
	@$(MAKE) -s dc-dc CMD="up -d $(APPS_SYS)" || echo ""
	@for f in $(shell echo $(APPS)) ; do $(MAKE) -s $${f}-apply ; done

## do init..up steps via single command
install: init apply gitea-setup u

# ------------------------------------------------------------------------------
## Other
#:

## delete unused docker images w/o name
## (you should use portainer for this)
clean-noname:
	docker rmi $$(docker images | grep "<none>" | awk "{print \$$3}")

## delete docker dangling volumes
## (you should use portainer for this)
clean-volume:
	docker volume rm $$(docker volume ls -qf dangling=true)

