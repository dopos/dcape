# CIS init Makefile
# This file included by ../../Makefile

SHELL               = /bin/bash

# DCAPE_USED==1 when called from upper Makefile
DCAPE_USED         ?= 0
# Narra Docker image version by dcape
CIS_NARRA_VER0     ?= 0.23
# Webtail Docker image version
CIS_NARRA_VER      ?= $(CIS_NARRA_VER0)
# CIS hostname
CIS_HOST           ?= $(DOMAIN)
# Gitea host for auth
CIS_GITEA_HOST     ?= git.$(DOMAIN)
# Gitea organization for users who has access to private areas
CIS_GITEA_ORG      ?= dcape
# Auth service access token: client ID
AUTH_CLIENT_ID     ?= ***-get_access_token_from_gitea-***
# Auth service access token: key
AUTH_CLIENT_KEY    ?= ***-get_access_token_from_gitea-***
# Key to sign CIS token
CIS_SIGN_KEY       ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 2>/dev/null | head -c32; echo)
# Key to crypt CIS token
CIS_CRYPT_KEY      ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 2>/dev/null | head -c32; echo)

define CONFIG_CIS
# ------------------------------------------------------------------------------
# CI site settings

# App hostname
CIS_HOST=$(CIS_HOST)

# Gitea host for auth
CIS_GITEA_HOST=$(CIS_GITEA_HOST)
# Gitea organization for users who has access to CIS
CIS_GITEA_ORG=$(CIS_GITEA_ORG)

# Auth service access token: client ID
AUTH_CLIENT_ID=$(AUTH_CLIENT_ID)
# Auth service access token: key
AUTH_CLIENT_KEY=$(AUTH_CLIENT_KEY)

# Key to sign CIS token
CIS_SIGN_KEY=$(CIS_SIGN_KEY)
# Key to crypt CIS token
CIS_CRYPT_KEY=$(CIS_CRYPT_KEY)

# Narra Docker image version
CIS_NARRA_VER=$(CIS_NARRA_VER)
endef
export CONFIG_CIS

cis-init:
	@grep CIS_SIGN_KEY .env || echo "$$CONFIG_CIS" >> .env
	@if [[ "$$CIS_NARRA_VER0" != "$$CIS_NARRA_VER" ]] ; then \
	  echo "Warning: CIS_NARRA_VER in dcape ($$CIS_NARRA_VER0) differs from yours ($$CIS_NARRA_VER)" ; \
	fi

cis-apply:
