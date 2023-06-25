# powerdns init Makefile
# This file included by ../../Makefile
SHELL             = /bin/bash

# Docker image version tested for actual dcape release
PDNS_VER0        ?= v4.8.0

#- ******************************************************************************
#- Powerdns: general config

#- [ip:]port powerdns listen on
PDNS_LISTEN      ?= 54
#- Stats site host
PDNS_HOST        ?= ns.$(DCAPE_DOMAIN)
#- Wildcard zone nameserver
#- NS value for $(DCAPE_DOMAIN) CNAME record
#- Used for zone SOA record & for internal access from traefik
ACME_NS          ?= ns.$(DCAPE_DOMAIN)
#- Setup ACME zone for this domain
#- CNAME value for $(DCAPE_DOMAIN) record
ACME_DOMAIN      ?= acme-$(DCAPE_DOMAIN)
#- Admin email for wildcard zone SOA recors
ACME_ADMIN_EMAIL ?= $(TRAEFIK_ACME_EMAIL)

#- ------------------------------------------------------------------------------
#- Powerdns: internal config

#- Database name and database user name
PDNS_DB_TAG      ?= pdns
#- Database user password
PDNS_DB_PASS     ?= $(shell openssl rand -hex 16; echo)
#- Powerdns API key for DNS-01 ACME challenges
PDNS_API_KEY     ?= $(shell openssl rand -hex 16; echo)
#- powerdns docker image version
PDNS_VER         ?= $(PDNS_VER0)

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

# load powerdns zone from zone.sql
powerdns-load-zone: zone.sql docker-wait
	cat zone.sql | docker exec -i $$PG_CONTAINER psql -U $$PDNS_DB_TAG -d $$PDNS_DB_TAG