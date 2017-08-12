# Drone init Makefile
# This file included by ../../Makefile

SHELL               = /bin/bash

# DCAPE_USED==1 when called from upper Makefile
DCAPE_USED         ?= 0
# Database name and database user name
GITEA_DB_TAG       ?= gitea
# Database user password
GITEA_DB_PASS      ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 | head -c14; echo)
# Gitea hostname prefix
GITEA_HOST_PREFIX  ?= git
# Gitea hostname
GITEA_HOST  ?= $(GITEA_HOST_PREFIX).$(DOMAIN)

define CONFIG_GITEA
# ------------------------------------------------------------------------------
# Gitea settings

# App hostname
GITEA_HOST=$(GITEA_HOST)

# Database user password
GITEA_DB_PASS=$(GITEA_DB_PASS)

endef
export CONFIG_GITEA

GITEA_INI_DIR ?= var/data/gitea/gitea/conf

# Init data for $${GITEA_INI_DIR}/app.ini
define INI_GITEA
[server]
SSH_DOMAIN = $(GITEA_HOST)
DOMAIN     = $(GITEA_HOST)
ROOT_URL   = http://$(GITEA_HOST)/

[database]
DB_TYPE    = postgres
HOST       = db:5432
NAME       = $(GITEA_DB_TAG)
USER       = $(GITEA_DB_TAG)
SSL_MODE   = disable

[log]
ROOT_PATH  = /data/log
endef
export INI_GITEA


gitea-init:
	@echo "$$CONFIG_GITEA" >> .env


gitea-apply:
	@$(MAKE) -s db-create NAME=$(GITEA_DB_TAG)
	@[ -d $$GITEA_INI_DIR ] || mkdir -p $$GITEA_INI_DIR
	@[ -f $$GITEA_INI_DIR/app.ini ] || echo "$$INI_GITEA" > $$GITEA_INI_DIR/app.ini
	@[ -d var/log/gitea ] || mkdir -p var/log/gitea
	@chown 1000 var/log/gitea $$GITEA_INI_DIR/app.ini
