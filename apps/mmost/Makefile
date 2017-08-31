# Mattermost init Makefile
# This file included by ../../Makefile

SHELL               = /bin/bash

# DCAPE_USED==1 when called from upper Makefile
DCAPE_USED         ?= 0
# Mattermost Docker image version by dcape
MMOST_VER0         ?= 4.1.0
# Mattermost Docker image version
MMOST_VER          ?= $(MMOST_VER0)
# Database name and database user name
MMOST_DB_TAG       ?= mmost
# Database user password
MMOST_DB_PASS      ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 | head -c14; echo)
# Drone hostname prefix
MMOST_HOST_PREFIX  ?= chat
# Drone hostname
MMOST_HOST         ?= $(MMOST_HOST_PREFIX).$(DOMAIN)

define CONFIG_MMOST
# ------------------------------------------------------------------------------
# Mattermost settings

# Mattermost Docker image version
MMOST_VER=$(MMOST_VER)

# App hostname
MMOST_HOST=$(MMOST_HOST)

# Database name and database user name
MMOST_DB_TAG=$(MMOST_DB_TAG)

# Database user password
MMOST_DB_PASS=$(MMOST_DB_PASS)

endef
export CONFIG_MMOST

mmost-init:
	@grep MMOST_ .env > /dev/null || echo "$$CONFIG_MMOST" >> .env
	@if [[ "$$MMOST_VER0" != "$$MMOST_VER" ]] ; then \
  echo "Warning: MMOST_VER in dcape ($$MMOST_VER0) differs from yours ($$MMOST_VER)" ; \
  fi

mmost-apply:
	@$(MAKE) -s db-create NAME=MMOST
