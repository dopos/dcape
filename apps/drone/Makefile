# Drone init Makefile
# This file included by ../../Makefile

SHELL               = /bin/bash

# DCAPE_USED==1 when called from upper Makefile
DCAPE_USED         ?= 0

# Add this to domain for default hostname
DRONE_HOST_PREFIX   = drone

# Drone hostname
DRONE_HOST         ?= $(DRONE_HOST_PREFIX).$(DOMAIN)

# drone/drone docker image version from dcape
DRONE_VER0         ?= 1.9
# drone/drone docker image version
DRONE_VER          ?= $(DRONE_VER0)
# drone/drone-runner-docker docker image version
DRONE_RUNNER_VER   ?= 1.6.1

# Database name and database user name
DRONE_DB_TAG      ?= drone
# Database user password
DRONE_DB_PASS     ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 2>/dev/null | head -c14; echo)

# Gitea user who will be Drone admin
DRONE_ADMIN        ?= admin
# Gitea server
DRONE_GIT_SERVER   ?= $(DCAPE_SCHEME)://$(CIS_GITEA_HOST)

# Auth service access token: client ID
DRONE_CLIENT_ID     ?= ***-get_access_token_from_gitea-***
# Auth service access token: key
DRONE_CLIENT_KEY    ?= ***-get_access_token_from_gitea-***

# Shared key for runners
DRONE_SHARED_KEY   ?= $(shell openssl rand -hex 16; echo)

define CONFIG_DRONE
# ------------------------------------------------------------------------------
# drone settings

# Drone hostname
DRONE_HOST=$(DRONE_HOST)

# drone/drone docker image version
DRONE_VER=$(DRONE_VER)
# drone/drone-runner-docker docker image version
DRONE_RUNNER_VER=$(DRONE_RUNNER_VER)

# Database name and database user name
DRONE_DB_TAG=$(DRONE_DB_TAG)
# Database user password
DRONE_DB_PASS=$(DRONE_DB_PASS)

# Gitea user who will be Drone admin
DRONE_ADMIN=$(DRONE_ADMIN)
# Gitea server
DRONE_GIT_SERVER=$(DRONE_GIT_SERVER)
# Auth service access token: client ID
DRONE_CLIENT_ID=$(DRONE_CLIENT_ID)
# Auth service access token: key
DRONE_CLIENT_KEY=$(DRONE_CLIENT_KEY)
# Shared key for runners
DRONE_SHARED_KEY=$(DRONE_SHARED_KEY)

endef
export CONFIG_DRONE

drone-init:
	@grep DRONE_ .env > /dev/null || echo "$$CONFIG_DRONE" >> .env
	@if [[ "$$DRONE_VER0" != "$$DRONE_VER" ]] ; then \
	  echo "Warning: DRONE_VER in dcape ($$DRONE_VER0) differs from yours ($$DRONE_VER)" ; \
	fi

drone-apply:
	@cmd=create ; \
	$(MAKE) -s db-create NAME=DRONE
