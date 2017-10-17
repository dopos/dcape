# CIS init Makefile
# This file included by ../../Makefile

SHELL               = /bin/bash

# DCAPE_USED==1 when called from upper Makefile
DCAPE_USED         ?= 0
# Webtail Docker image version by dcape
CIS_WEBTAIL_VER0   ?= 0.11.0
# Webtail Docker image version
CIS_WEBTAIL_VER    ?= $(CIS_WEBTAIL_VER0)
# Webhook Docker image version by dcape
CIS_WEBHOOK_VER0   ?= 0.4
# Webtail Docker image version
CIS_WEBHOOK_VER    ?= $(CIS_WEBHOOK_VER0)
# Narra Docker image version by dcape
CIS_NARRA_VER0     ?= 0.3
# Webtail Docker image version
CIS_NARRA_VER    ?= $(CIS_NARRA_VER0)
# CIS hostname prefix
CIS_HOST_PREFIX    ?= cis
# CIS hostname
CIS_HOST           ?= $(CIS_HOST_PREFIX).$(DOMAIN)
# Gitea host for auth
CIS_GITEA_HOST     ?= http://gitea:3000
# Gitea organization for users who has access to CIS
CIS_GITEA_ORG      ?= dcape
# Key to sign CIS token
CIS_SIGN_KEY       ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 | head -c32; echo)
# Key to crypt CIS token
CIS_CRYPT_KEY      ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 | head -c32; echo)
# Webhook access password
CIS_DEPLOY_PASS    ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 | head -c8; echo)
# webhook needs to know dcape root
DCAPE_ROOT         ?= $(shell pwd)

define CONFIG_CIS
# ------------------------------------------------------------------------------
# CI site settings

# App hostname
CIS_HOST=$(CIS_HOST)

# Private admin site part (traefik, consul, webtail, dns) token
# Gitea host for auth
CIS_GITEA_HOST=$(CIS_GITEA_HOST)
# Gitea organization for users who has access to CIS
CIS_GITEA_ORG=$(CIS_GITEA_ORG)
# Key to sign CIS token
CIS_SIGN_KEY=$(CIS_SIGN_KEY)
# Key to crypt CIS token
CIS_CRYPT_KEY=$(CIS_CRYPT_KEY)

# Webhook access password
CIS_DEPLOY_PASS=$(CIS_DEPLOY_PASS)

# Webtail Docker image version
CIS_WEBTAIL_VER=$(CIS_WEBTAIL_VER)
# Webhook Docker image version
CIS_WEBHOOK_VER=$(CIS_WEBHOOK_VER)
# Narra Docker image version
CIS_NARRA_VER=$(CIS_NARRA_VER)

# CIS webhook must have same root as dcape
DCAPE_ROOT=$(DCAPE_ROOT)

endef
export CONFIG_CIS

cis-init:
	@grep CIS_DEPLOY .env || \
	{ \
	  echo "$$CONFIG_CIS" >> .env ; \
	  echo "** CIS DEPLOY PASSWORD: $$CIS_DEPLOY_PASS" ; \
	}
	@if [[ "$$CIS_WEBTAIL_VER0" != "$$CIS_WEBTAIL_VER" ]] ; then \
	  echo "Warning: CIS_WEBTAIL_VER in dcape ($$CIS_WEBTAIL_VER0) differs from yours ($$CIS_WEBTAIL_VER)" ; \
	fi
	@if [[ "$$CIS_WEBHOOK_VER0" != "$$CIS_WEBHOOK_VER" ]] ; then \
	  echo "Warning: CIS_WEBHOOK_VER in dcape ($$CIS_WEBHOOK_VER0) differs from yours ($$CIS_WEBHOOK_VER)" ; \
	fi
	@if [[ "$$CIS_NARRA_VER0" != "$$CIS_NARRA_VER" ]] ; then \
	  echo "Warning: CIS_NARRA_VER in dcape ($$CIS_NARRA_VER0) differs from yours ($$CIS_NARRA_VER)" ; \
	fi

cis-apply: var/apps var/data/cis var/data/cis/hook.pub var/log/webhook
	@echo "*** $@ ***"

var/apps:
	@echo "*** $@ ***"
	@[ -d $@ ] || mkdir -p $@

var/log/webhook:
	@echo "*** $@ ***"
	@[ -d $@ ] || mkdir -p $@

var/data/cis:
	@echo "*** $@ ***"
	@[ -d $@ ] || mkdir -p $@

var/data/cis/hook.pub:
	@echo "*** $@ ***"
	ssh-keygen -t rsa -b 1024 -f var/data/cis/hook -N "" -C webhook@$$DOMAIN

#	ssh-keygen -t ed25519 -f var/data/cis/hook -N "" -C webhook@$$DOMAIN
