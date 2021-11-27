## Drone setup
#:
# This file included by ../../Makefile
SHELL               = /bin/bash
# drone/drone docker image version from dcape
DRONE_VER0         ?= 2.4.0
# Config vars are described below in section `define CONFIG_...`
DRONE_HOST         ?= drone.$(DCAPE_DOMAIN)
DRONE_ADMIN        ?= dcapeadmin
DRONE_CLIENT_ID    ?= =DRONE_CLIENT_ID=
DRONE_CLIENT_KEY   ?= =DRONE_CLIENT_KEY=
DRONE_DB_TAG       ?= drone
DRONE_DB_PASS      ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 2>/dev/null | head -c14; echo)
DRONE_VER          ?= $(DRONE_VER0)
DRONE_RUNNER_VER   ?= 1.7.0
DRONE_SHARED_KEY   ?= $(shell openssl rand -hex 16; echo)
DRONE_COPLA_KEY    ?= $(shell openssl rand -hex 16; echo)
DRONE_VAR_PATH     ?= $(PWD)/$(DCAPE_VAR)

define CONFIG_DRONE
# ==============================================================================
# Drone: general config

# Drone hostname
DRONE_HOST=$(DRONE_HOST)

# Gitea user who will be Drone admin
DRONE_ADMIN=$(DRONE_ADMIN)

# Auth service access token: client ID
DRONE_CLIENT_ID=$(DRONE_CLIENT_ID)
# Auth service access token: key
DRONE_CLIENT_KEY=$(DRONE_CLIENT_KEY)

# ------------------------------------------------------------------------------
# Drone: internal config

# Database name and database user name
DRONE_DB_TAG=$(DRONE_DB_TAG)
# Database user password
DRONE_DB_PASS=$(DRONE_DB_PASS)
# Shared key for runners
DRONE_SHARED_KEY=$(DRONE_SHARED_KEY)
# Deployment persistent storage, absolute
DRONE_VAR_PATH=$(DRONE_VAR_PATH)
# Drone conversion for platform tag (drocopla) key
DRONE_COPLA_KEY=$(DRONE_COPLA_KEY)

# drone/drone docker image version
DRONE_VER=$(DRONE_VER)
# drone/drone-runner-docker docker image version
DRONE_RUNNER_VER=$(DRONE_RUNNER_VER)

endef
export CONFIG_DRONE

# ------------------------------------------------------------------------------

## add drone config to $(CFG)
drone-init:
	@grep DRONE_VER $(CFG) > /dev/null || echo "$$CONFIG_DRONE" >> $(CFG)
	@if [[ "$$DRONE_VER0" != "$$DRONE_VER" ]] ; then \
	  echo "Warning: DRONE_VER in dcape ($$DRONE_VER0) differs from yours ($$DRONE_VER)" ; \
	fi
	@echo "  URL: $(DCAPE_SCHEME)://$(DRONE_HOST)"
	@echo "  Admin: $(DRONE_ADMIN)"

## create drone DB
drone-apply:
	@cmd=create ; \
	$(MAKE) -s db-create NAME=DRONE

## build dcape-compose image
## for drone and dcape-app
drone-build: CMD=build compose
drone-build: dc
