# Mattermost init Makefile
# This file included by ../../Makefile

SHELL               = /bin/bash

# DCAPE_USED==1 when called from upper Makefile
DCAPE_USED         ?= 0
# Database name and database user name
MMOST_DB_TAG       ?= drone
# Database user password
MMOST_DB_PASS      ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 | head -c14; echo)
# Drone hostname prefix
MMOST_HOST_PREFIX  ?= mmost
# Drone hostname
MMOST_HOST         ?= $(MMOST_HOST_PREFIX).$(DOMAIN)

define CONFIG_MMOST
# ------------------------------------------------------------------------------
# Mattermost settings

# App hostname
MMOST_HOST=$(MMOST_HOST)

# Database user password
MMOST_DB_PASS=$(MMOST_DB_PASS)

endef
export CONFIG_MMOST

mmost-init:
	@echo "$$CONFIG_MMOST" >> .env

mmost-apply:
	@$(MAKE) -s db-create NAME=$(MMOST_DB_TAG)
