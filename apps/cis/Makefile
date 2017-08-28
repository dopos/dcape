# CIS init Makefile
# This file included by ../../Makefile

SHELL               = /bin/bash

# DCAPE_USED==1 when called from upper Makefile
DCAPE_USED         ?= 0
# Webtail Docker image version
CIS_WEBTAIL_VER    ?= 0.11.0
# Login of admin user in CIR restricted areas
CIS_AREA_LOGIN     ?= admin
# Password of admin user in CIS restricted areas
CIS_AREA_PASS      ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 | head -c8; echo)
# CIS hostname prefix
CIS_HOST_PREFIX    ?= cis
# CIS hostname
CIS_HOST           ?= $(CIS_HOST_PREFIX).$(DOMAIN)
# ssh key file name
SSH_KEY_NAME       ?= hook

define CONFIG_CIS
# ------------------------------------------------------------------------------
# CI site settings

# App hostname
CIS_HOST=$(CIS_HOST)

# Private admin site part (traefik, consul, webtail, dns)
CIS_AREA_LOGIN=$(CIS_AREA_LOGIN)
CIS_AREA_PASS=$(CIS_AREA_PASS)

# Webtail Docker image version
CIS_WEBTAIL_VER=$(CIS_WEBTAIL_VER)

endef
export CONFIG_CIS


# Init data for /services.json
define JSON_CIS
var services = {
  "gitea": "${GITEA_HOST}",
  "mmost": "${MMOST_HOST}",
  "drone": "${DRONE_HOST}",
  "port":  "${PORTAINER_HOST}"
};
var port = "${TRAEFIK_PORT}";
endef
export JSON_CIS

cis-init:
	@grep CIS_AREA .env || \
  { \
    echo "$$CONFIG_CIS" >> .env ; \
    echo "** CIS AREA LOGIN:    $(CIS_AREA_LOGIN)" ; \
    echo "** CIS AREA PASSWORD: $(CIS_AREA_PASS)" ; \
  }

cis-apply: var/data/cis var/data/cis/htpasswd var/data/cis/html/services.json var/data/cis/html/$(SSH_KEY_NAME).pub
	@echo "*** $@ ***"

var/data/cis:
	@echo "*** $@ ***"
	@[ -d var/data/cis ] || mkdir var/data/cis
	@cp -pr apps/cis/{nginx.conf,html,hooks} var/data/cis

var/data/cis/html/services.json:
	@echo "*** $@ ***"
	echo "$$JSON_CIS" > var/data/cis/html/services.json

var/data/cis/htpasswd:
	@echo "*** $@ ***"
	@P=$$(echo $$CIS_AREA_PASS | openssl passwd -stdin) && echo "$$CIS_AREA_LOGIN:$$P" > var/data/cis/htpasswd

var/data/cis/html/$(SSH_KEY_NAME).pub:
	@echo "*** $@ ***"
	ssh-keygen -t rsa -b 4096 -f $(SSH_KEY_NAME) -N "" -C webhook@$$DOMAIN
	@mv $(SSH_KEY_NAME) var/data/cis/hooks/
	@mv $(SSH_KEY_NAME).pub var/data/cis/html/
