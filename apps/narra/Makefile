# narra init Makefile
# This file included by ../../Makefile
SHELL               = /bin/bash
# Default docker image version
NARRA_VER0         ?= 0.23
# Config vars described below in section `define CONFIG_...`
NARRA_GITEA_ORG    ?= dcape
NARRA_CLIENT_ID    ?= =NARRA_CLIENT_ID=
NARRA_CLIENT_KEY   ?= =NARRA_CLIENT_KEY=
NARRA_SIGN_KEY     ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 2>/dev/null | head -c32; echo)
NARRA_CRYPT_KEY    ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 2>/dev/null | head -c32; echo)
NARRA_VER          ?= $(NARRA_VER0)

define CONFIG_NARRA
# ==============================================================================
# Narra: general config

# Gitea organization for users who has access to private areas
NARRA_GITEA_ORG=$(NARRA_GITEA_ORG)

# Auth service access token: client ID
NARRA_CLIENT_ID=$(NARRA_CLIENT_ID)
# Auth service access token: key
NARRA_CLIENT_KEY=$(NARRA_CLIENT_KEY)

# ------------------------------------------------------------------------------
# Narra: internal config

# Key to sign narra token
NARRA_SIGN_KEY=$(NARRA_SIGN_KEY)
# Key to crypt narra token
NARRA_CRYPT_KEY=$(NARRA_CRYPT_KEY)

# Narra Docker image version
NARRA_VER=$(NARRA_VER)

endef
export CONFIG_NARRA

# ------------------------------------------------------------------------------

narra-init:
	@grep NARRA_SIGN_KEY $(CFG) || echo "$$CONFIG_NARRA" >> $(CFG)
	@if [[ "$$NARRA_VER0" != "$$NARRA_VER" ]] ; then \
	  echo "Warning: NARRA_VER in dcape ($$NARRA_VER0) differs from yours ($$NARRA_VER)" ; \
	fi

narra-apply:
