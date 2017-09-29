# Traefik-acme init Makefile
# This file included by ../../Makefile

SHELL               = /bin/bash

# DCAPE_USED==1 when called from upper Makefile
DCAPE_USED         ?= 0
# Traefik Docker image version by dcape
TRAEFIK_VER0       ?= 1.4
# Traefik Docker image version
TRAEFIK_VER        ?= $(TRAEFIK_VER0)
# Traefik external port (used in no-acme config)
TRAEFIK_PORT       ?= 80
# Traefik Let's encrypt email (used in acme config)
TRAEFIK_ACME_EMAIL ?= your@mail

define CONFIG_TRAEFIKA
# ------------------------------------------------------------------------------
# Traefik-acme settings

# Traefik Docker image version
TRAEFIK_VER=$(TRAEFIK_VER)

# Not used in this config but must be defined for docker-compose
TRAEFIK_PORT=$(TRAEFIK_PORT)

# Let's encrypt user email
TRAEFIK_ACME_EMAIL=$(TRAEFIK_ACME_EMAIL)

endef
export CONFIG_TRAEFIKA

traefik-acme-init:
	@grep Traefik-acme .env > /dev/null || echo "$$CONFIG_TRAEFIKA" >> .env
	@if [[ "$$TRAEFIK_VER0" != "$$TRAEFIK_VER" ]] ; then \
	  echo "Warning: TRAEFIK_VER in dcape ($$TRAEFIK_VER0) differs from yours ($$TRAEFIK_VER)" ; \
	fi

traefik-acme-apply:
