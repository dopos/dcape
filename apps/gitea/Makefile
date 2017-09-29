# Gitea init Makefile
# This file included by ../../Makefile

SHELL               = /bin/bash

# DCAPE_USED==1 when called from upper Makefile
DCAPE_USED         ?= 0
# Gitea Docker image version by dcape
GITEA_VER0         ?= latest
# Gitea Docker image version
GITEA_VER          ?= $(GITEA_VER0)
# Database name and database user name
GITEA_DB_TAG       ?= gitea
# Database user password
GITEA_DB_PASS      ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 | head -c14; echo)
# Gitea ssh server port
GITEA_SSH_PORT     ?= 10022
# Gitea hostname prefix
GITEA_HOST_PREFIX  ?= git
# Gitea hostname
GITEA_HOST         ?= $(GITEA_HOST_PREFIX).$(DOMAIN)

# Internal gitea config path
GITEA_INI_DIR      ?= var/data/gitea/gitea/conf

define CONFIG_GITEA
# ------------------------------------------------------------------------------
# Gitea settings

# Gitea Docker image version
GITEA_VER=$(GITEA_VER)

# App hostname
GITEA_HOST=$(GITEA_HOST)

# Gitea ssh server port
# You should change sshd port and set this to 22
GITEA_SSH_PORT=$(GITEA_SSH_PORT)

# Database name and database user name
GITEA_DB_TAG=$(GITEA_DB_TAG)

# Database user password
GITEA_DB_PASS=$(GITEA_DB_PASS)

endef
export CONFIG_GITEA


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
	@grep GITEA_DB_PASS .env || \
	{ \
	  echo "$$CONFIG_GITEA" >> .env ; \
	  echo "** GITEA DB PASSWORD: $(GITEA_DB_PASS)" ; \
	}
	@if [[ "$$GITEA_VER0" != "$$GITEA_VER" ]] ; then \
	  echo "Warning: GITEA_VER in dcape ($$GITEA_VER0) differs from yours ($$GITEA_VER)" ; \
	fi

gitea-apply:
	@$(MAKE) -s db-create NAME=GITEA
	@[ -d $$GITEA_INI_DIR ] || mkdir -p $$GITEA_INI_DIR
	@[ -f $$GITEA_INI_DIR/app.ini ] || echo "$$INI_GITEA" > $$GITEA_INI_DIR/app.ini
	@[ -d var/log/gitea ] || mkdir -p var/log/gitea
	@chmod 777 var/log/gitea
	@chmod 666 $$GITEA_INI_DIR/app.ini
