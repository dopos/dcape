# Portainer init Makefile
# This file included by ../../Makefile

SHELL                 = /bin/bash

# DCAPE_USED==1 when called from upper Makefile
DCAPE_USED           ?= 0
# Portainer Docker image version by dcape
PORTAINER_VER0       ?= 1.15.5
# Portainer Docker image version
PORTAINER_VER        ?= $(PORTAINER_VER0)
# Portainer hostname prefix
PORTAINER_HOST_PREFIX = port
# Portainer hostname
PORTAINER_HOST       ?= $(PORTAINER_HOST_PREFIX).$(DOMAIN)

define CONFIG_PORTAINER
# ------------------------------------------------------------------------------
# Portainer settings

# Docker image version
PORTAINER_VER=$(PORTAINER_VER)

# App hostname
PORTAINER_HOST=$(PORTAINER_HOST)

endef
export CONFIG_PORTAINER

portainer-init:
	@grep PORTAINER_ .env > /dev/null || echo "$$CONFIG_PORTAINER" >> .env
	@if [[ "$$PORTAINER_VER0" != "$$PORTAINER_VER" ]] ; then \
	  echo "Warning: PORTAINER_VER in dcape ($$PORTAINER_VER0) differs from yours ($$PORTAINER_VER)" ; \
	fi

portainer-apply:
