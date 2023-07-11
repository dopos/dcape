# dcape Makefile
# used to control dcape stack

SHELL             = /bin/bash
CFG               = .env

#- ******************************************************************************
#- DCAPE: general config

#- dcape containers hostname domain
DCAPE_DOMAIN     ?= dev.lan

#- dcape containers hostname domain
DCAPE_ROOT       ?= $(PWD)

#- container name prefix
DCAPE_TAG        ?= dcape

#- CICD_ADMIN - CICD admin user
#- GITEA_ADMIN_NAME - Gitea admin user name
DCAPE_ADMIN_USER ?= dcapeadmin

# VCS OAuth app owner
DCAPE_ADMIN_ORG  ?= dcape

#- dcape apps
#- calculated by install
#- used in make only
APPS     ?=

# internal makefile var
DCAPE_STACK = yes

#- ------------------------------------------------------------------------------
#- DCAPE: internal config

#- dcape services frontend hostname
DCAPE_HOST         ?= $(DCAPE_DOMAIN)
#- docker network name
DCAPE_NET        ?= $(DCAPE_TAG)
#- docker internal network name
DCAPE_NET_INTRA  ?= $(DCAPE_TAG)_intra
#- create db cluster with this timezone
#- (also used by containers)
TZ               ?= $(shell cat /etc/timezone)
#- docker network subnet
DCAPE_SUBNET     ?= 100.127.0.0/24
#- docker intra network subnet
DCAPE_SUBNET_INTRA ?= 100.127.255.0/24
#- Deployment persistent storage, relative
DCAPE_VAR        ?= $(DCAPE_ROOT)/var

#- (auto) http(s)
DCAPE_SCHEME ?=
#- gitea url
AUTH_URL ?=
#- db container
DB_CONTAINER     ?= $(DCAPE_TAG)-db-1

ENFIST_URL       ?= http://enfist:8080/rpc

DCAPE_CORE = yes


-include $(CFG).bak
-include $(CFG)
export

all: help

ifneq ($(findstring $(MAKECMDGOALS),install),)
  include Makefile.install
endif

APPS_DIRS  = $(addprefix $(DCAPE_ROOT)/apps/_,$(APPS))

# make a list $APP -> -f apps/$APP/docker-compose.inc.yml
DC_SOURCES = $(addsuffix /docker-compose.inc.yml,$(APPS_DIRS))
DC_SRC_ARG = $(addprefix -f ,$(DC_SOURCES))

# make a list $APP -> --env-file apps/$APP/.env
DC_ENV_SOURCES = $(addsuffix /.env,$(APPS_DIRS))
DC_ENV_ARG = $(addprefix --env-file ,$(DC_ENV_SOURCES))
DC_INC = docker-compose.inc.yml


include Makefile.dcape

# create docker-compose image
compose:
	docker build -t ${DCAPE_TAG}-compose --build-arg DCAPE_HOST_ROOT=${PWD} .

info-dcape:
	@echo $(APPS)

