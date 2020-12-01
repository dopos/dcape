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
# Values: local|acme-http|acme
TRAEFIK_CONFIG_TAG ?= local

# Traefik hostname for internal access
# This allows narra & drone internal access to gitea without DNS, in "no any lan" config
TRAEFIK_ALIAS      ?= $(GITEA_HOST)
# Some non-empty value when GITEA_HOST is external
TRAEFIK_ALIAS      ?= $(CIS_HOST)


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
# Values: local|acme-http|acme
TRAEFIK_CONFIG_TAG=$(TRAEFIK_CONFIG_TAG)

# Traefik hostname for internal access
TRAEFIK_ALIAS=$(TRAEFIK_ALIAS)
endef
export CONFIG_TRAEFIK

traefik-init: var/traefik/custom var/traefik/traefik.env
	@grep TRAEFIK_ .env > /dev/null || echo "$$CONFIG_TRAEFIK" >> .env
	@if [[ "$$TRAEFIK_VER0" != "$$TRAEFIK_VER" ]] ; then \
	  echo "Warning: TRAEFIK_VER in dcape ($$TRAEFIK_VER0) differs from yours ($$TRAEFIK_VER)" ; \
	fi

traefik-apply: var/traefik/traefik.yml var/traefik/acme.json

var/traefik/custom:
	@mkdir -p $@

var/traefik/traefik.yml: apps/traefik/traefik.$(TRAEFIK_CONFIG_TAG).yml
	@sed "s/=DCAPE_TAG=/$$PROJECT_NAME/g" $< | sed "s/=DCAPE_DOMAIN=/$$DOMAIN/g" > $@

var/traefik/acme.json:
	@touch $@
	@chmod 600 $@

define ENV_TRAEFIK
# ENV data for traefik plugins including acme)

# Sample for local powerdns:

#LEGO_EXPERIMENTAL_CNAME_SUPPORT=true
#PDNS_API_URL=http://pdns:8081
#PDNS_API_KEY=***-see_powerdns_config-***

endef
export ENV_TRAEFIK

var/traefik/traefik.env:
	echo "$$ENV_TRAEFIK" > $@
