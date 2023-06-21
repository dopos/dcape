# dcape Makefile
SHELL             = /bin/bash
CFG               = .env

#- ******************************************************************************
#- Postgresql: general config

#- Postgresql docker image
PG_IMAGE         ?= citusdata/citus
#- Postgresql docker image version
PG_VER           ?= 11.3-alpine
#postgres:13.5-alpine

#- ------------------------------------------------------------------------------
#- Postgresql: internal config

#- Postgresql container hostname
PG_HOSTNAME      ?= db

#- Postgresql Database superuser password
PG_DB_PASS       ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 2>/dev/null | head -c14; echo)
#- Postgresql Database encoding
PG_ENCODING      ?= en_US.UTF-8
#- port on localhost postgresql listen on
PG_PORT_LOCAL    ?= 5433
#- Dump name suffix to load on db-create
PG_SOURCE_SUFFIX ?=
#- shared memory
PG_SHM_SIZE      ?= 64mb
#- initdbargs for customise create postgres cluster
PG_INITDB_ARGS      ?= --lc-message=C

# ------------------------------------------------------------------------------

