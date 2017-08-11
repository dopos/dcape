SHELL = /bin/bash
DCAPE_USED ?= 0

define CONFIG_PORTAINER
# ------------------------------------------------------------------------------
# Portainer settings

# App hostname
PORTAINER_HOST=port.$(DOMAIN)

endef
export CONFIG_PORTAINER

portainer-init:
	@echo "$$CONFIG_PORTAINER" >> .env

portainer-apply:
