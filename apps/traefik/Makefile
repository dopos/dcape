# Traefik init Makefile
# This file included by ../../Makefile

SHELL               = /bin/bash

# DCAPE_USED==1 when called from upper Makefile
DCAPE_USED         ?= 0
# Traefik Docker image version by dcape
TRAEFIK_VER0       ?= 1.4.0
# Traefik Docker image version
TRAEFIK_VER        ?= $(TRAEFIK_VER0)
# Traefik external port (used in no-acme config)
TRAEFIK_PORT       ?= 80

define CONFIG_TRAEFIK
# ------------------------------------------------------------------------------
# Traefik settings

# Traefik Docker image version
TRAEFIK_VER=$(TRAEFIK_VER)

# Proxy external port
TRAEFIK_PORT=$(TRAEFIK_PORT)

endef
export CONFIG_TRAEFIK

traefik-init:
	@grep TRAEFIK_ .env > /dev/null || echo "$$CONFIG_TRAEFIK" >> .env
	@if [[ "$$TRAEFIK_VER0" != "$$TRAEFIK_VER" ]] ; then \
	  echo "Warning: TRAEFIK_VER in dcape ($$TRAEFIK_VER0) differs from yours ($$TRAEFIK_VER)" ; \
	fi

traefik-apply:
