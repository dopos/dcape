# Traefik init Makefile
# This file included by ../../Makefile

SHELL               = /bin/bash

# DCAPE_USED==1 when called from upper Makefile
DCAPE_USED         ?= 0
# Traefik Docker image version by dcape
TRAEFIK_VER0       ?= 2.3.4
# Traefik Docker image version
TRAEFIK_VER        ?= $(TRAEFIK_VER0)
# Traefik external http port
TRAEFIK_PORT       ?= 80
# Traefik external https port
TRAEFIK_PORT_SSL   ?= 443

# Tag for apps/traefik/traefik.TAG.yml
TRAEFIK_CONFIG_TAG ?= local

define CONFIG_TRAEFIK
# ------------------------------------------------------------------------------
# Traefik settings

# Traefik Docker image version
TRAEFIK_VER=$(TRAEFIK_VER)

# Traefik external http port
TRAEFIK_PORT=$(TRAEFIK_PORT)

# Traefik external https port
TRAEFIK_PORT_SSL=$(TRAEFIK_PORT_SSL)

# Tag for apps/traefik/traefik.TAG.yml
TRAEFIK_CONFIG_TAG=$(TRAEFIK_CONFIG_TAG)

endef
export CONFIG_TRAEFIK

traefik-init:
	@grep TRAEFIK_ .env > /dev/null || echo "$$CONFIG_TRAEFIK" >> .env
	@if [[ "$$TRAEFIK_VER0" != "$$TRAEFIK_VER" ]] ; then \
	  echo "Warning: TRAEFIK_VER in dcape ($$TRAEFIK_VER0) differs from yours ($$TRAEFIK_VER)" ; \
	fi

traefik-apply:var/traefik/custom var/traefik/traefik.yml var/traefik/acme.json

var/traefik/custom:
	@mkdir -p $@

var/traefik/traefik.yml: apps/traefik/traefik.$(TRAEFIK_CONFIG_TAG).yml
	@cp $< $@

var/traefik/acme.json:
	@touch $@
	@chmod 600 $@
