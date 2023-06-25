# Traefik init Makefile
# This file included by ../../Makefile
SHELL               = /bin/bash

# Docker image version tested for actual dcape release
TRAEFIK_VER0       ?= 2.9.10

#- ******************************************************************************
#- Traefik: general config

#- dcape services frontend hostname
DCAPE_HOST         ?= $(DCAPE_DOMAIN)
#- Traefik external http port
TRAEFIK_LISTEN     ?= 80

#- Traefik external https port
TRAEFIK_LISTEN_SSL ?= 443
#- Let's encrypt user email
#- Value used only in `make apply` and saved in traefik.yml
TRAEFIK_ACME_EMAIL ?= admin@$(DCAPE_DOMAIN)

#- ------------------------------------------------------------------------------
#- Traefik: internal config

#- Docker image version
TRAEFIK_VER        ?= $(TRAEFIK_VER0)

#- Traefik hostname for internal access
#- This allows narra & drone internal access to local gitea without DNS
#- Used when host computer has no any ethernet interfaces
TRAEFIK_ALIAS      ?=

# ------------------------------------------------------------------------------

# TRAEFIK_CONFIG_TAG - Tag for apps/traefik/traefik.TAG.yml
# Values: local|acme-http|acme
# Used only in `make apply`
ifeq ($(ACME),no)
  TRAEFIK_CONFIG_TAG ?= local
else ifeq ($(ACME),yes)
  TRAEFIK_CONFIG_TAG ?= acme-http
  CONFIG_TRAEFIK += $(CONFIG_TRAEFIK_EMAIL)
else
  TRAEFIK_CONFIG_TAG ?= acme
  CONFIG_TRAEFIK += $(CONFIG_TRAEFIK_EMAIL)
endif
CONFIG_TRAEFIK += $(CONFIG_TRAEFIK_INTERNAL)
ifeq ($(DNS),no)
  PDNS_API_KEY = ***-see_powerdns_config-***
endif
ifeq ($(GITEA),yes)
  TRAEFIK_ALIAS ?= $(GITEA_HOST)
else
  TRAEFIK_ALIAS ?= $(DCAPE_HOST)
endif
export CONFIG_TRAEFIK

# ------------------------------------------------------------------------------

traefik-init: $(DCAPE_VAR)/traefik/custom $(DCAPE_VAR)/traefik/traefik.env
	@grep TRAEFIK_ $(CFG) > /dev/null || echo "$$CONFIG_TRAEFIK" >> $(CFG)
	@if [[ "$$TRAEFIK_VER0" != "$$TRAEFIK_VER" ]] ; then \
	  echo "Warning: TRAEFIK_VER in dcape ($$TRAEFIK_VER0) differs from yours ($$TRAEFIK_VER)" ; \
	fi
	@echo "  Dashboard URL: $(DCAPE_SCHEME)://$(DCAPE_HOST)/dashboard/"
	@echo "  HTTP port: $(TRAEFIK_LISTEN)"

traefik-apply: $(DCAPE_VAR)/traefik/traefik.yml $(DCAPE_VAR)/traefik/acme.json

$(DCAPE_VAR)/traefik/custom:
	@mkdir -p $@

$(DCAPE_VAR)/traefik/traefik.yml: apps/traefik/traefik.$(TRAEFIK_CONFIG_TAG).yml
	@sed "s/=DCAPE_TAG=/$$DCAPE_TAG/g ; s/=DCAPE_DOMAIN=/$$DCAPE_DOMAIN/g ; s/=TRAEFIK_EMAIL=/$$TRAEFIK_ACME_EMAIL/g" $<  > $@

$(DCAPE_VAR)/traefik/acme.json:
	@touch $@
	@chmod 600 $@

define ENV_TRAEFIK
# ENV data for traefik plugins (pdns etc)

# Sample for local powerdns:

##LEGO_EXPERIMENTAL_CNAME_SUPPORT=true
##PDNS_API_URL=http://powerdns:8081
##PDNS_API_KEY=$(PDNS_API_KEY)

endef
export ENV_TRAEFIK

$(DCAPE_VAR)/traefik/traefik.env:
ifeq ($(DNS),no)
	touch $@
else ifeq ($(DNS),yes)
	echo "$$ENV_TRAEFIK" > $@
else
	echo "$$ENV_TRAEFIK" | sed "s/##//g" > $@
endif
