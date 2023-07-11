# dcape application Makefile
# included by separate dcape app

SHELL             = /bin/bash

USE_DB       ?= no
USE_TLS      ?= no
TLS_RESOLVER ?= letsEncrypt

USE_DCAPE_DC  ?= yes
DCAPE_DC_YML  ?= $(DCAPE_ROOT)/docker-compose.app.yml

mkfile_path := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))
include $(mkfile_path)/Makefile.common

up: CMD=up -d
up: dc

reup: CMD=up --force-recreate -d
reup: dc


dc:
	@[ "$(DCAPE_DC_USED)" != yes ] || args="-f $(DCAPE_DC_YML)" ; \
	docker compose $$args -f docker-compose.yml \
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
