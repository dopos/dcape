# dcape application Makefile
# included by separate dcape app

SHELL          = /bin/bash
CFG           ?= .env

DOT       := .
DASH      := -


# website host, value must be set in app Makefile
APP_SITE        ?= app.dev.lan

#- Unique traefik router name
#- Container name prefix
#- Value is optional, derived from APP_SITE if empty
APP_TAG         ?= $(subst $(DOT),$(DASH),$(APP_SITE))

#- Enable tls in traefik
#- Values: [false]|true
USE_TLS       ?= no

USE_DB        ?= no

#- tls cert resolver
TLS_RESOLVER  ?= letsEncrypt

#- dc root
DCAPE_ROOT         ?= /opt/dcape

#- dcape stack traefik tag
DCAPE_TAG       ?= dcape

#- dcape stack network
DCAPE_NET       ?= $(DCAPE_TAG)

USE_DCAPE_DC  ?= yes
DCAPE_DC_YML  ?= $(DCAPE_ROOT)/docker-compose.app.yml
DCAPE_APP_DC_YML ?= docker-compose.yml

mkfile_path := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))
include $(mkfile_path)/Makefile.common

# ------------------------------------------------------------------------------
# Docker operations

up: CMD=up -d
up: dc

reup: CMD=up --force-recreate -d
reup: dc

dc:
	@[ "$(USE_DCAPE_DC)" != yes ] || args="-f $(DCAPE_DC_YML)" ; \
	docker compose $$args -f $(DCAPE_APP_DC_YML) \
	  --project-directory $$PWD \
	  $(CMD)

# ------------------------------------------------------------------------------
# DB operations

PGDATABASE      ?= $(APP_NAME)
PGUSER          ?= $(APP_NAME)
PGPASSWORD      ?= $(shell openssl rand -hex 16; echo)
PG_DUMP_SOURCE  ?=


ifeq ($(USE_DB),yes)

define CONFIG_DB

# ------------------------------------------------------------------------------
# Database name
PGDATABASE=$(PGDATABASE)
# Database user name
PGUSER=$(PGUSER)
# Database user password
PGPASSWORD=$(PGPASSWORD)
# Database dump for import on create
# Used as ${PG_DUMP_SOURCE}.{tar|tgz}
PG_DUMP_SOURCE=$(PG_DUMP_SOURCE)

endef
endif

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

## run app by CICD
## use inside .woodpecker.yml only
.default-deploy: .config-link
	@echo "*** $@ ***" ; \
	[ "$$USE_DB" != "yes" ] || $(MAKE) -s db-create ; \
	if [ ! -z "$$PERSIST_FILES" ] ; then \
	  echo "Persist not implemented" ; \
	 # . setup root $(SETUP_ROOT_OPTS) ; \
	 # cp -r $$PERSIST_FILES $$APP_ROOT ; \
	fi ; \
	[ "$(USE_DCAPE_DC)" != yes ] || args="-f $(DCAPE_DC_YML)" ; \
	docker compose -p $(APP_TAG) --env-file $(CFG) $$args -f $(DCAPE_APP_DC_YML) up -d --force-recreate

.config-link:
	@if [ -z "$$ENFIST_TAG" ]; then \
	  ENFIST_TAG=$${CI_REPO_OWNER}--$${CI_REPO_NAME}--$${CI_COMMIT_BRANCH} ; \
	fi ; \
	echo -n "Setup config for $${ENFIST_TAG}... " ; \
	curl -gs http://config:8080/rpc/tag_vars?code=$$ENFIST_TAG | jq -er '.' > $(CFG) && echo "Ok" || { \
	  rm $(CFG) # here will be `null` if tag does not exists ; \
	  echo "NOT FOUND" ; \
	  [ -f $(CFG).sample ] || $(MAKE) -s $(CFG).sample ; \
	  jq -R -sc ". | {\"code\":\"$$ENFIST_TAG.sample\",\"data\":.}" < $(CFG).sample \
	    | curl -gsd \@- "http://config:8080/rpc/tag_set" | jq '.' ; \
	  echo "Edit config $$ENFIST_TAG.sample and rename it to $$ENFIST_TAG" ; \
	  exit 1 ; \
	}
