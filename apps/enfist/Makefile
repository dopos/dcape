# Drone init Makefile

# This file included by ../../Makefile

SHELL               = /bin/bash

# DCAPE_USED==1 when called from upper Makefile
DCAPE_USED         ?= 0
# Database name and database user name
ENFIST_DB_TAG      ?= enfist
# Database user password
ENFIST_DB_PASS     ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 | head -c14; echo)
# dbrpc docker image version
ENFIST_DBRPC_VER    ?= 0.27

define CONFIG_ENFIST
# ------------------------------------------------------------------------------
# enfist settings

# Database name and database user name
ENFIST_DB_TAG=$(ENFIST_DB_TAG)

# Database user password
ENFIST_DB_PASS=$(ENFIST_DB_PASS)

# dbrpc docker image version (uncomment for update by hand)
# ENFIST_DBRPC_VER=$(ENFIST_DBRPC_VER)

endef
export CONFIG_ENFIST

enfist-init:
	@grep ENFIST_ .env > /dev/null || echo "$$CONFIG_ENFIST" >> .env

enfist-apply:
	@$(MAKE) -s db-create NAME=ENFIST \
  && docker run -d --rm --name $${PROJECT_NAME}_enfist_temp_start lekovr/dbrpc:$${ENFIST_DRPC_VER} --wait 5 \
  && docker cp $${PROJECT_NAME}_enfist_temp_start:/opt/sql var/sql.tmp \
  && cp apps/enfist/sql/Makefile var/sql.tmp/Makefile \
  && pushd var/sql.tmp > /dev/null && $(MAKE) -s build-docker PG_USER=$${ENFIST_DB_TAG} && popd > /dev/null \
  && pushd apps/enfist/sql > /dev/null && $(MAKE) -s build-docker PG_USER=$${ENFIST_DB_TAG} && popd > /dev/null \
  && rm -rf var/sql.tmp
