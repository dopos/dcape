SHELL   = /bin/bash

PG_CONTAINER ?= dcape_db_1
PG_USER      ?= dbrpc

.PHONY: help build-docker build-psql clean-docker clean-psql

# ------------------------------------------------------------------------------

all: help

## Load sql via running docker container
build-docker:
	@echo "*** $@ ***" \
  && echo -n "Checking PG is ready..." \
  && until [[ `docker inspect -f "{{.State.Health.Status}}" $(PG_CONTAINER)` == healthy ]] ; do sleep 1 ; echo -n "." ; done \
  && echo "Ok" \
  && cat *.sql | docker exec -i $(PG_CONTAINER) psql -U $(PG_USER) -1 -v ON_ERROR_STOP=1

## Load sql via psql command
build-psql:
	@echo "*** $@ ***" \
  && ls -1 *.sql | xargs -n 1 echo "\i" | psql -U $(PG_USER) -1 -v ON_ERROR_STOP=1

## Drop database schema rpc via psql command
clean-docker:
	@echo "*** $@ ***" \
  && echo -n "Checking PG is ready..." \
  && until [[ `docker inspect -f "{{.State.Health.Status}}" $(PG_CONTAINER)` == healthy ]] ; do sleep 1 ; echo -n "." ; done \
  && echo "Ok" \
  && docker exec -i $(PG_CONTAINER psql) -U $(PG_USER) -c "DROP SCHEMA rpc CASCADE;"

## Drop database schema rpc via psql command
clean-psql:
	@echo "*** $@ ***" \
  && psql -U $(PG_USER) -c "DROP SCHEMA rpc CASCADE;"

# ------------------------------------------------------------------------------

## List Makefile targets
help:
	@grep -A 1 "^##" Makefile | less

##
## Press 'q' for exit
##
