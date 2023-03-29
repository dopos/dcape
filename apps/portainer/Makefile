# Portainer init Makefile
# This file included by ../../Makefile
SHELL                 = /bin/bash
# Docker image version
PORTAINER_VER0       ?= 2.15.1-alpine
# Config vars are described below in section `define CONFIG_...`
PORTAINER_HOST       ?= port.$(DCAPE_DOMAIN)
PORTAINER_VER        ?= $(PORTAINER_VER0)

define CONFIG_PORTAINER
# ==============================================================================
# Portainer config

# Portainer hostname
PORTAINER_HOST=$(PORTAINER_HOST)

# Docker image version
PORTAINER_VER=$(PORTAINER_VER)

endef

export CONFIG_PORTAINER

# ------------------------------------------------------------------------------

portainer-init:
	@grep PORTAINER_VER $(CFG) > /dev/null || echo "$$CONFIG_PORTAINER" >> $(CFG)
	@if [[ "$$PORTAINER_VER0" != "$$PORTAINER_VER" ]] ; then \
	  echo "Warning: PORTAINER_VER in dcape ($$PORTAINER_VER0) differs from yours ($$PORTAINER_VER)" ; \
	fi
	@echo "  URL: $(DCAPE_SCHEME)://$(PORTAINER_HOST)"

portainer-apply:
