# Drone init Makefile

# This file included by ../../Makefile

SHELL               = /bin/bash

# DCAPE_USED==1 when called from upper Makefile
DCAPE_USED         ?= 0
# Database name and database user name
ENFIST_DB_TAG      ?= enfist
# Database user password
ENFIST_DB_PASS     ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 | head -c14; echo)
# dbrpc docker image version by dcape
ENFIST_DBRPC_VER0   ?= 0.27
# dbrpc docker image version
ENFIST_DBRPC_VER    ?= $(ENFIST_DBRPC_VER0)

# Internal pgrpc-sql packages
ENFIST_SQL_RPC_VERSION    ?= 0.3
ENFIST_SQL_ENFIST_VERSION ?= 0.2

define CONFIG_ENFIST
# ------------------------------------------------------------------------------
# enfist settings

# Database name and database user name
ENFIST_DB_TAG=$(ENFIST_DB_TAG)

# Database user password
ENFIST_DB_PASS=$(ENFIST_DB_PASS)

# dbrpc docker image version
ENFIST_DBRPC_VER=$(ENFIST_DBRPC_VER)

endef
export CONFIG_ENFIST

enfist-init:
	@grep ENFIST_ .env > /dev/null || echo "$$CONFIG_ENFIST" >> .env
	@if [[ "$$ENFIST_DBRPC_VER0" != "$$ENFIST_DBRPC_VER" ]] ; then \
	  echo "Warning: ENFIST_DBRPC_VER in dcape ($$ENFIST_DBRPC_VER0) differs from yours ($$ENFIST_DBRPC_VER)" ; \
	fi

enfist-apply:
	@$(MAKE) -s db-create NAME=ENFIST || true
	[ -d var/enfist-tmp ] || mkdir var/enfist-tmp
	pushd var/enfist-tmp > /dev/null \
	&& curl -sL https://github.com/pgrpc/pgrpc-sql-rpc/archive/v${ENFIST_SQL_RPC_VERSION}.tar.gz | tar -xvz \
	&& pushd pgrpc-sql-rpc-${ENFIST_SQL_RPC_VERSION} > /dev/null \
	&& $(MAKE) -s create TOOL=docker SCHEMA=rpc PG_CONTAINER=$${PROJECT_NAME}_db_1 DB_USER=$${ENFIST_DB_TAG} \
	&& popd > /dev/null \
	&& curl -sL https://github.com/pgrpc/pgrpc-sql-enfist/archive/v${ENFIST_SQL_ENFIST_VERSION}.tar.gz | tar -xvz \
	&& pushd pgrpc-sql-enfist-${ENFIST_SQL_ENFIST_VERSION} > /dev/null \
	&& $(MAKE) -s create TOOL=docker SCHEMA=env PG_CONTAINER=$${PROJECT_NAME}_db_1 DB_USER=$${ENFIST_DB_TAG} \
	&& popd > /dev/null \
	&& popd > /dev/null \
	&& rm -rf var/enfist-tmp
