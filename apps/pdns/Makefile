SHELL = /bin/bash
DCAPE_USED ?= 0

define CONFIG_PDNS
# ------------------------------------------------------------------------------
# PowerDNS settings

# DNS server port
PDNS_PORT=54

PDNS_DB_PASS=change_me

endef
export CONFIG_PDNS

pdns-init:
	@echo "$$CONFIG_PDNS" >> .env

pdns-apply:
	@echo "*** $@ ***"
	@$(MAKE) -s db-create NAME=pdns
	@pass=$${PDNS_DB_PASS} \
  && CONTAINER=$${PROJECT_NAME}_db_1 \
  && docker run -t --rm lekovr/powerdns cat /usr/share/doc/pdns/schema.pgsql.sql \
   | docker exec -i $$CONTAINER psql -U pdns -f -
