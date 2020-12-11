# powerdns init Makefile
# This file included by ../../Makefile
SHELL             = /bin/bash
# psitrax/powerdns docker image version by dcape
PDNS_VER0        ?= v4.3
# Config vars described below in section `define CONFIG_...`
PDNS_LISTEN      ?= 54
PDNS_HOST        ?= ns.$(DCAPE_DOMAIN)
ACME_DOMAIN      ?= $(DCAPE_DOMAIN)
ACME_NS          ?= ns.$(ACME_DOMAIN)
ACME_ADMIN_EMAIL ?= admin@$(DCAPE_DOMAIN)
PDNS_DB_TAG      ?= pdns
PDNS_DB_PASS     ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 2>/dev/null | head -c14; echo)
PDNS_API_KEY     ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 | head -c14; echo)
PDNS_VER         ?= $(PDNS_VER0)

define CONFIG_PDNS
# ==============================================================================
# Powerdns: general config

# [ip:]port powerdns listen on
PDNS_LISTEN=$(PDNS_LISTEN)

# Stats site host
PDNS_HOST=$(PDNS_HOST)

# Setup ACME zone for this domain
ACME_DOMAIN=$(ACME_DOMAIN)

# Wildcard zone nameserver
ACME_NS=$(ACME_NS)

# Admin email for wildcard zone SOA recors
ACME_ADMIN_EMAIL=$(ACME_ADMIN_EMAIL)

# ------------------------------------------------------------------------------
# Powerdns: internal config

# Database name and database user name
PDNS_DB_TAG=$(PDNS_DB_TAG)

# Database user password
PDNS_DB_PASS=$(PDNS_DB_PASS)

# Powerdns API key for DNS-01 ACME challenges
PDNS_API_KEY=$(PDNS_API_KEY)

# psitrax/powerdns docker image version
PDNS_VER=$(PDNS_VER)

endef
export CONFIG_PDNS

# ------------------------------------------------------------------------------

powerdns-init:
	@grep PDNS_VER $(CFG) > /dev/null || echo "$$CONFIG_PDNS" >> $(CFG)
	@if [[ "$$PDNS_VER0" != "$$PDNS_VER" ]] ; then \
	  echo "Warning: PDNS_VER in dcape ($$PDNS_VER0) differs from yours ($$PDNS_VER)" ; \
	fi

# create user, db and load sql
powerdns-apply: docker-wait
	@echo "*** $@ ***" \
	docker exec -i $$PG_CONTAINER psql -U postgres -c "CREATE USER \"$$PDNS_DB_TAG\" WITH PASSWORD '$$PDNS_DB_PASS';" 2> >(grep -v "already exists" >&2) \
	&& docker exec -i $$PG_CONTAINER psql -U postgres -c "CREATE DATABASE \"$$PDNS_DB_TAG\" OWNER \"$$PDNS_DB_TAG\";" 2> >(grep -v "already exists" >&2) || db_exists=1 ; \
	if [[ ! "$$db_exists" ]] ; then \
	  PGPASSWORD=$${PDNS_DB_PASS} \
	  && cat apps/powerdns/schema.pgsql.sql | docker exec -i $$PG_CONTAINER psql -U $$PDNS_DB_TAG -d $$PDNS_DB_TAG \
	  && [[ "$$DNS" != "wild" ]] || cat apps/powerdns/setup.acme.sql | docker exec -i $$PG_CONTAINER psql -U $$PDNS_DB_TAG -d $$PDNS_DB_TAG \
	    -vACME_DOMAIN=$$ACME_DOMAIN -vACME_NS=$$ACME_NS -vNS_ADMIN=$$ACME_ADMIN_EMAIL \
	    || true ; \
	fi
