# enfist init Makefile
# This file included by ../../Makefile
SHELL               = /bin/bash
# Docker image version
ENFIST_VER0        ?= 0.6.2
# Config vars are described below in section `define CONFIG_...`
ENFIST_DB_TAG      ?= enfist
ENFIST_DB_PASS     ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 2>/dev/null | head -c14; echo)
ENFIST_VER         ?= $(ENFIST_VER0)

define CONFIG_ENFIST
# ==============================================================================
# Enfist config

# Database name and database user name
ENFIST_DB_TAG=$(ENFIST_DB_TAG)

# Database user password
ENFIST_DB_PASS=$(ENFIST_DB_PASS)

# apisite/app-enfist docker image version
ENFIST_VER=$(ENFIST_VER)

endef
export CONFIG_ENFIST

# ------------------------------------------------------------------------------

enfist-init:
	@grep ENFIST_VER $(CFG) > /dev/null || echo "$$CONFIG_ENFIST" >> $(CFG)
	@if [[ "$$ENFIST_VER0" != "$$ENFIST_VER" ]] ; then \
	  echo "Warning: ENFIST_VER in dcape ($$ENFIST_VER0) differs from yours ($$ENFIST_VER)" ; \
	fi
	@echo "  URL: $(DCAPE_SCHEME)://$(DCAPE_HOST)/conf/"


enfist-apply:
	@cmd=create ; \
	$(MAKE) -s db-create NAME=ENFIST
	PGPASSWORD=$${ENFIST_DB_PASS} \
	&& cat apps/enfist/migrate.sql | docker exec -i $$PG_CONTAINER psql -U $$ENFIST_DB_TAG $$ENFIST_DB_TAG
	$(MAKE) -s dc CMD="run --rm enfist make poma-install"
