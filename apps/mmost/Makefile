SHELL = /bin/bash
DCAPE_USED ?= 0

define CONFIG_MMOST
# ------------------------------------------------------------------------------
# Mattermost settings

# App hostname
MMOST_HOST=chat.$(DOMAIN)

MMOST_DB_PASS=change_me

endef
export CONFIG_MMOST

mmost-init:
	@echo "$$CONFIG_MMOST" >> .env

mmost-apply:
	@$(MAKE) -s db-create NAME=mmost
