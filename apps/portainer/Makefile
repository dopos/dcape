# Portainer init Makefile
# This file included by ../../Makefile

SHELL                 = /bin/bash

# DCAPE_USED==1 when called from upper Makefile
DCAPE_USED           ?= 0
# Portainer hostname prefix
PORTAINER_HOST_PREFIX = port
# Portainer hostname
PORTAINER_HOST       ?= $(PORTAINER_HOST_PREFIX).$(DOMAIN)

SHELL = /bin/bash
DCAPE_USED ?= 0

define CONFIG_PORTAINER
# ------------------------------------------------------------------------------
# Portainer settings

# App hostname
PORTAINER_HOST=$(PORTAINER_HOST)

endef
export CONFIG_PORTAINER

portainer-init:
	@echo "$$CONFIG_PORTAINER" >> .env

portainer-apply:
