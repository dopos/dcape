# powerdns init Makefile
# This file included by ../../Makefile
SHELL             = /bin/bash
# psitrax/powerdns docker image version by dcape
PDNS_VER0        ?= v4.3
# Config vars are described below in section `define CONFIG_...`
PDNS_LISTEN      ?= 54
PDNS_HOST        ?= ns.$(DCAPE_DOMAIN)
ACME_DOMAIN      ?= acme-$(DCAPE_DOMAIN)
ACME_NS          ?= ns.$(DCAPE_DOMAIN)
ACME_ADMIN_EMAIL ?= $(TRAEFIK_ACME_EMAIL)
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

# Wildcard zone nameserver
# NS value for $(DCAPE_DOMAIN) CNAME record
# Used for zone SOA record & for internal access from traefik
ACME_NS=$(ACME_NS)

# Setup ACME zone for this domain
# CNAME value for $(DCAPE_DOMAIN) record
ACME_DOMAIN=$(ACME_DOMAIN)

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
	@echo "  Stats URL: $(DCAPE_SCHEME)://$(PDNS_HOST)"
	@echo "  Listen: $(PDNS_LISTEN)"

# create user, db and load sql
powerdns-apply: docker-wait
	@echo "*** $@ ***" ; \
	docker exec -i $$PG_CONTAINER psql -U postgres -c "CREATE USER \"$$PDNS_DB_TAG\" WITH PASSWORD '$$PDNS_DB_PASS';" 2> >(grep -v "already exists" >&2) \
	&& docker exec -i $$PG_CONTAINER psql -U postgres -c "CREATE DATABASE \"$$PDNS_DB_TAG\" OWNER \"$$PDNS_DB_TAG\";" 2> >(grep -v "already exists" >&2) || db_exists=1 ; \
	if [[ ! "$$db_exists" ]] ; then \
	  PGPASSWORD=$${PDNS_DB_PASS} \
	  && cat apps/powerdns/schema.pgsql.sql | docker exec -i $$PG_CONTAINER psql -U $$PDNS_DB_TAG -d $$PDNS_DB_TAG \
	  && [[ "$$DNS" != "wild" ]] || cat apps/powerdns/setup.acme.sql | docker exec -i $$PG_CONTAINER psql -U $$PDNS_DB_TAG -d $$PDNS_DB_TAG \
	    -vACME_DOMAIN=$$ACME_DOMAIN -vACME_NS=$$ACME_NS -vNS_ADMIN=$$ACME_ADMIN_EMAIL \
	    || true ; \
	fi
