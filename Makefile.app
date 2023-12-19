# dcape application Makefile
# included by separate dcape app

SHELL          = /bin/bash
CFG           ?= .env

DOT       := .
DASH      := -

APP_NAME           ?= $(lastword $(subst /, ,$(PWD)))

#- Site host
APP_SITE        ?= $(APP_NAME).$(DCAPE_DOMAIN)

#- Unique traefik router name
#- Container name prefix
#- Value is optional, derived from APP_SITE if empty
APP_TAG         ?= $(subst $(DOT),$(DASH),$(APP_SITE))

#- Enable tls in traefik
#- Values: [false]|true
USE_TLS       ?= false

#- Attach database
#- Values: [no]|yes
USE_DB        ?= no

#- Add user account data to config
ADD_USER      ?= no

#- dc root
DCAPE_ROOT         ?= /opt/dcape

#- dcape stack traefik tag
DCAPE_TAG       ?= dcape

#- dcape stack network
DCAPE_NET       ?= $(DCAPE_TAG)

# Docker compose project name (container name prefix)
PROJECT_NAME     ?= $(APP_TAG)

USE_DCAPE_DC     ?= yes
DCAPE_DC_YML     ?= $(DCAPE_ROOT)/docker-compose.app.yml
DCAPE_APP_DC_YML ?= docker-compose.yml
DB_CONTAINER     ?= $(DCAPE_TAG)-db-1

all: help

DCAPE_ROOT ?= $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))
-include $(DCAPE_ROOT)/.dcape.env
include $(DCAPE_ROOT)/Makefile.common

# ------------------------------------------------------------------------------

# used in URL generation
ifeq ($(USE_TLS),false)
HTTP_PROTO ?= http
else
HTTP_PROTO ?= https
endif

# ------------------------------------------------------------------------------
## Docker operations
#:

## (re)start container(s)
up: CMD=up -d
up: dc

## restart container
reup: CMD=up --force-recreate -d
reup: dc

## stop (and remove) container(s)
down: CMD=rm -f -s
down: dc

#down: CMD=down

## Build docker image
docker-build: CMD=build --no-cache app
docker-build: dc

## Remove docker image & temp files
docker-clean:
	[ "$$(docker images -q $(DC_IMAGE) 2> /dev/null)" = "" ] || docker rmi $(DC_IMAGE)

dc:
	@[ "$(USE_DCAPE_DC)" != yes ] || args="-f $(DCAPE_DC_YML)" ; \
	docker compose $$args -f $(DCAPE_APP_DC_YML) \
	  -p $(PROJECT_NAME) --project-directory $$PWD \
	  $(CMD)

# ------------------------------------------------------------------------------
## DB operations
#:

## create database and user
db-create:
ifeq ($(USE_DB),yes)
	@echo "*** $@ ***" ; \
	$(MAKE) -s .lib-db-create
else
	@echo "Target '$@' is disabled in app config"
endif

## drop database and user
db-drop:
ifeq ($(USE_DB),yes)
	@echo "*** $@ ***"
	$(MAKE) -s .lib-db-drop
else
	@echo "Target '$@' is disabled in app config"
endif

## exec psql inside db container
psql: docker-wait
ifeq ($(USE_DB),yes)
	@echo "*** $@ ***"
	@docker exec -it $${DB_CONTAINER:?Must be set} psql -d $$PGDATABASE -U $$PGUSER
else
	@echo "Target '$@' is disabled in app config"
endif

## run local psql
## (Add DB_PORT_LOCAL to .env before use)
psql-local:
ifeq ($(USE_DB),yes)
	@echo "*** $@ ***"
	psql -p $(DB_PORT_LOCAL)
#	$(MAKE) -s .lib-db-psql
else
	@echo "Target '$@' is disabled in app config"
endif

#
# ------------------------------------------------------------------------------
# CI/CD operations

# run app by CICD
# use inside .woodpecker.yml only
.default-deploy: .config-link
	@echo "*** $@ ***" ; \
	[ "$$USE_DB" != "yes" ] || $(MAKE) -s db-create ; \
	$(MAKE) -s .up

# internal target, do not used
.deploy-vars:
	@echo "DCAPE_ROOT_BASE=$${DCAPE_ROOT_BASE}"
	@echo "DCAPE_ROOT_LOCAL=$${DCAPE_ROOT_LOCAL}"
	@echo "DCAPE_TAG:$${DCAPE_TAG}"
	@echo "DCAPE_NET:$${DCAPE_NET}"
	@echo "DCAPE_ROOT:$${DCAPE_ROOT}"
	@echo "DCAPE_DOMAIN:$${DCAPE_DOMAIN}"
	@echo "DCAPE_COMPOSE:$${DCAPE_COMPOSE}"
	@echo "DCAPE_SCM:$${DCAPE_SCM}"

# internal target for .default-deploy
.up: KEEP_ROOT = $(findstring $(APP_ROOT_OPTS),keep)
.up:
	@if [ ! -z "$$PERSIST_FILES" ] ; then \
	  echo "Got persist ($$PERSIST_FILES) for $$APP_ROOT.." ; \
	  dir=$${DCAPE_ROOT_LOCAL}/$(ENFIST_TAG); \
	  echo "Local dir: $$dir" >&2 ; \
	  if [ -d $$dir ] && [ -z "$(KEEP_ROOT)" ]; then \
	    echo -n "Clean dir.. " >&2 ; \
	    rm -rf $$dir ; \
	  fi ; \
	  if [ ! -d $$dir ]; then \
	    echo -n "Create dir.. " >&2 ; \
	    mkdir -p $$dir ; \
	  fi ; \
	  cp -rf $$PERSIST_FILES $$dir ; \
	fi ; \
	echo "Starting.. " >&2 ; \
	[ "$(USE_DCAPE_DC)" != yes ] || args="-f $(DCAPE_DC_YML)" ; \
	docker compose -p $(APP_TAG) --env-file $(CFG) -f $(DCAPE_APP_DC_YML) $$args up -d --force-recreate

# build app by CICD
# use inside .woodpecker.yml only
.build:
	[ "$(USE_DCAPE_DC)" != yes ] || args="-f $(DCAPE_DC_YML)" ; \
	docker compose -p $(APP_TAG) -f $(DCAPE_APP_DC_YML) $$args build

# setup .env by CICD
# used inside .woodpecker.yml by .default-deploy
.config-link: ENFIST_BRANCH ?= $(CI_COMMIT_BRANCH)
.config-link: ENFIST_TAG ?= $(CI_REPO_OWNER)--$(CI_REPO_NAME)--$(ENFIST_BRANCH)
.config-link: APP_ROOT    = $(DCAPE_ROOT_BASE)/$(ENFIST_TAG)
.config-link:
	@echo -n "Setup config for $${ENFIST_TAG}... " ; \
	if curl -gsS "http://config:8080/rpc/tag_vars?code=$$ENFIST_TAG" | jq -er '.' > $(CFG).temp ; then \
	  mv $(CFG).temp $(CFG) ; echo "Ok" ; \
	else \
	  rm $(CFG).temp # here will be `null` if tag does not exists ; \
	  echo "NOT FOUND" ; \
	  [ -f $(CFG).sample ] || $(MAKE) -s $(CFG).sample ; \
	  jq -R -sc ". | {\"code\":\"$$ENFIST_TAG.sample\",\"data\":.}" < $(CFG).sample \
	    | curl -gsd \@- "http://config:8080/rpc/tag_set" | jq '.' ; \
	  echo "Edit config $$ENFIST_TAG.sample and rename it to $$ENFIST_TAG" ; \
	  exit 1 ; \
	fi
