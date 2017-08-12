# Drone init Makefile
# This file included by ../../Makefile

SHELL               = /bin/bash

# DCAPE_USED==1 when called from upper Makefile
DCAPE_USED         ?= 0
# Database name and database user name
PDNS_DB_TAG        ?= pdns
# Database user password
PDNS_DB_PASS       ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 | head -c14; echo)
# DNS tcp/udp port
PDNS_PORT          ?= 54
# PowerDNS docker image
PDNS_IMAGE         ?= lekovr/powerdns
# Path to schema.pgsql.sql in PowerDNS docker image
PDNS_PGSQL_PATH    ?= /usr/share/doc/pdns/schema.pgsql.sql

define CONFIG_PDNS
# ------------------------------------------------------------------------------
# PowerDNS settings

# DNS server port
PDNS_PORT=$(PDNS_PORT)

# Database user password
PDNS_DB_PASS=$(PDNS_DB_PASS)

endef
export CONFIG_PDNS

pdns-init:
	@echo "$$CONFIG_PDNS" >> .env

# pdns container nameBelow
pdns-apply:
	@echo "*** $@ ***"
	@$(MAKE) -s db-create NAME=$(PDNS_DB_TAG)
	@pass=$${PDNS_DB_PASS} \
  && CONTAINER=$${PROJECT_NAME}_db_1 \
  && docker run -t --rm $(PDNS_IMAGE) cat $(PDNS_PGSQL_PATH) \
   | docker exec -i $$CONTAINER psql -U pdns -f -
