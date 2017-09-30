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
# CIS hostname prefix
CIS_HOST_PREFIX    ?= cis
# CIS hostname
CIS_HOST           ?= $(CIS_HOST_PREFIX).$(DOMAIN)
# Login of admin user in CIR restricted areas
CIS_AREA_LOGIN     ?= admin
# Password of admin user in CIS restricted areas
CIS_AREA_PASS      ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 | head -c8; echo)
# Webhook access password
CIS_DEPLOY_PASS    ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 | head -c8; echo)
# For webhook container
DCAPE_ROOT         ?= $$PWD
define CONFIG_CIS
# ------------------------------------------------------------------------------
# CI site settings

# App hostname
CIS_HOST=$(CIS_HOST)

# Private admin site part (traefik, consul, webtail, dns)
CIS_AREA_LOGIN=$(CIS_AREA_LOGIN)
CIS_AREA_PASS=$(CIS_AREA_PASS)

# Webhook access password
CIS_DEPLOY_PASS=$(CIS_DEPLOY_PASS)

# Webtail Docker image version
CIS_WEBTAIL_VER=$(CIS_WEBTAIL_VER)
# Webhook Docker image version
CIS_WEBHOOK_VER=$(CIS_WEBHOOK_VER)

# CIS webhook must have same root
DCAPE_ROOT=$(DCAPE_ROOT)

endef
export CONFIG_CIS

cis-init:
	@grep CIS_AREA .env || \
	{ \
	  echo "$$CONFIG_CIS" >> .env ; \
	  echo "** CIS AREA LOGIN:      $$CIS_AREA_LOGIN" ; \
	  echo "** CIS AREA PASSWORD:   $$CIS_AREA_PASS" ; \
	  echo "** CIS DEPLOY PASSWORD: $$CIS_DEPLOY_PASS" ; \
	}
	@if [[ "$$CIS_WEBTAIL_VER0" != "$$CIS_WEBTAIL_VER" ]] ; then \
	  echo "Warning: CIS_WEBTAIL_VER in dcape ($$CIS_WEBTAIL_VER0) differs from yours ($$CIS_WEBTAIL_VER)" ; \
	fi
	@if [[ "$$CIS_WEBHOOK_VER0" != "$$CIS_WEBHOOK_VER" ]] ; then \
	  echo "Warning: CIS_WEBHOOK_VER in dcape ($$CIS_WEBHOOK_VER0) differs from yours ($$CIS_WEBHOOK_VER)" ; \
	fi

cis-apply: var/data/cis var/data/cis/htpasswd var/data/cis/hook.pub
	@echo "*** $@ ***"

var/data/cis:
	@echo "*** $@ ***"
	@[ -d var/data/cis ] || mkdir var/data/cis

# the only file needed in var. While gogs auth client does not written
var/data/cis/htpasswd:
	@echo "*** $@ ***"
	@P=$$(echo $$CIS_AREA_PASS | openssl passwd -stdin) && echo "$$CIS_AREA_LOGIN:$$P" > var/data/cis/htpasswd

var/data/cis/hook.pub:
	@echo "*** $@ ***"
	ssh-keygen -t rsa -b 1024 -f var/data/cis/hook -N "" -C webhook@$$DOMAIN

#	ssh-keygen -t ed25519 -f var/data/cis/hook -N "" -C webhook@$$DOMAIN
