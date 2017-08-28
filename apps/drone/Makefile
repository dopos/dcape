# Drone init Makefile
# This file included by ../../Makefile

SHELL               = /bin/bash

# DCAPE_USED==1 when called from upper Makefile
DCAPE_USED         ?= 0
# Password for drone-server <-> drone-agent exchange
DRONE_SECRET       ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 | head -c14; echo)
# Database name and database user name
DRONE_DB_TAG       ?= drone
# Database user password
DRONE_DB_PASS      ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 | head -c14; echo)
# Drone hostname prefix
DRONE_HOST_PREFIX  ?= drone
# Drone hostname
DRONE_HOST         ?= $(DRONE_HOST_PREFIX).$(DOMAIN)
# Gitea user who will be Drone admin
DRONE_ADMIN        ?= admin
# Gitea hostname
DRONE_GIT_HOST     ?= $(GITEA_HOST_PREFIX).$(DOMAIN)

define CONFIG_DRONE
# ------------------------------------------------------------------------------
# Drone settings

# App hostname
DRONE_HOST=$(DRONE_HOST)

# Password for drone-server <-> drone-agent exchange
DRONE_SECRET=$(DRONE_SECRET)

# Gitea URL
DRONE_GIT_URL=http://$(DRONE_GIT_HOST)/

# Gitea user who will be drone admin
DRONE_ADMIN=$(DRONE_ADMIN)

# Database name and database user name
DRONE_DB_TAG=$(DRONE_DB_TAG)

# Database user password
DRONE_DB_PASS=$(DRONE_DB_PASS)

endef
export CONFIG_DRONE

drone-init:
	@grep DRONE_ .env > /dev/null || echo "$$CONFIG_DRONE" >> .env

drone-apply:
	@$(MAKE) -s db-create NAME=DRONE
