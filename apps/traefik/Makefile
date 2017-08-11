SHELL = /bin/bash
DCAPE_USED ?= 0

define CONFIG_TRAEFIK
# ------------------------------------------------------------------------------
# Traefik settings

# Proxy external port
TRAEFIK_PORT=80

# Не используется в этой конфигурации, нужен для docker-compose
TRAEFIK_ACME_EMAIL=your@mail

endef
export CONFIG_TRAEFIK

traefik-init:
	@echo "$$CONFIG_TRAEFIK" >> .env

traefik-apply:
