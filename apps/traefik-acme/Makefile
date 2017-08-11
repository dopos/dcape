SHELL = /bin/bash
DCAPE_USED ?= 0

define CONFIG_TRAEFIKA
# ------------------------------------------------------------------------------
# Traefik-acme settings

# Let's encrypt user email
TRAEFIK_ACME_EMAIL=your@mail

endef
export CONFIG_TRAEFIKA

traefik-acme-init:
	@echo "$$CONFIG_TRAEFIKA" >> .env

traefik-acme-apply:
