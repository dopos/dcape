# Portainer init Makefile
# This file included by ../../Makefile
SHELL                 = /bin/bash

# Docker image version tested for actual dcape release
PORTAINER_VER0       ?= 2.18.4-alpine

#- ******************************************************************************
#- Portainer config

#- Portainer hostname
PORTAINER_HOST       ?= port.$(DCAPE_DOMAIN)
#- Docker image version
PORTAINER_VER        ?= $(PORTAINER_VER0)

# ------------------------------------------------------------------------------

portainer-init:
	@grep PORTAINER_VER $(CFG) > /dev/null || echo "$$CONFIG_PORTAINER" >> $(CFG)
	@if [[ "$$PORTAINER_VER0" != "$$PORTAINER_VER" ]] ; then \
	  echo "Warning: PORTAINER_VER in dcape ($$PORTAINER_VER0) differs from yours ($$PORTAINER_VER)" ; \
	fi
	@echo "  URL: $(DCAPE_SCHEME)://$(PORTAINER_HOST)"

portainer-apply:
