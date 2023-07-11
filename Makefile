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

DCAPE_MODE        = core
PG_CONTAINER     ?= $(DCAPE_TAG)-db-1

# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------

# if exists - load old values
-include $(CFG_BAK)
export

-include $(CFG)
export

.PHONY: init apply install

all: help

# ------------------------------------------------------------------------------
define CONFIG_DEF
# ******************************************************************************
# dcape extra config

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

# docker compose -f args
DC_SOURCES        = $(shell find apps -maxdepth 3 -mindepth 2 -name docker-compose.inc.yml)
DC_ARG_SRC        = $(addprefix -f ,$(DC_SOURCES))


# make a list $APP -> apps/$APP/Makefile.inc
MK_DIRS = $(addprefix apps/,core db $(APPS))
MK_SOURCES = $(addsuffix /Makefile.inc,$(MK_DIRS))

include $(MK_SOURCES)

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
	@$(MAKE) -s dc CMD="up -d $(APPS_SYS)" || echo ""
	@for f in $(shell echo $(APPS)) ; do $(MAKE) -s $${f}-apply ; done

gitea-install:
	@$(MAKE) -s dc CMD="up -d gitea" || echo ""
	@$(MAKE) -s gitea-admin
	@$(MAKE) -s gitea-setup

## do init..up steps via single command
install: init apply gitea-install up
