# Drone init Makefile

# This file included by ../../Makefile

SHELL               = /bin/bash

# DCAPE_USED==1 when called from upper Makefile
DCAPE_USED         ?= 0
# Database name and database user name
ENFIST_DB_TAG      ?= enfist
# Database user password
ENFIST_DB_PASS     ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 2>/dev/null | head -c14; echo)
# apisite/app-enfist docker image version by dcape
ENFIST_VER0        ?= 0.6.2
# apisite/app-enfist docker image version
ENFIST_VER         ?= $(ENFIST_VER0)

define CONFIG_ENFIST
# ------------------------------------------------------------------------------
# enfist settings

# Database name and database user name
ENFIST_DB_TAG=$(ENFIST_DB_TAG)

# Database user password
ENFIST_DB_PASS=$(ENFIST_DB_PASS)

# apisite/app-enfist docker image version
ENFIST_VER=$(ENFIST_VER)

endef
export CONFIG_ENFIST

enfist-init:
	@grep ENFIST_ .env > /dev/null || echo "$$CONFIG_ENFIST" >> .env
	@if [[ "$$ENFIST_VER0" != "$$ENFIST_VER" ]] ; then \
	  echo "Warning: ENFIST_VER in dcape ($$ENFIST_VER0) differs from yours ($$ENFIST_VER)" ; \
	fi

enfist-apply:
	@cmd=create ; \
	$(MAKE) -s db-create NAME=ENFIST
	DCAPE_DB=$${PROJECT_NAME}_db_1 \
	&& PGPASSWORD=$${ENFIST_DB_PASS} \
	&& cat apps/enfist/migrate.sql | docker exec -i $$DCAPE_DB psql -U $$ENFIST_DB_TAG $$ENFIST_DB_TAG
	$(MAKE) -s dc CMD="run --rm enfist make poma-install"
