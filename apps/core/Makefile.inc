
CFG               ?= .env

.PHONY: up reup down dc docker-wait db-create db-drop psql psql-local env-ls env-get env-set help

# ------------------------------------------------------------------------------
## Docker-compose commands
#:

ifeq ($(DCAPE_MODE),core)

## (re)start container(s)
up: CMD=up -d $(APPS)
up: dc

## restart container(s)
reup: CMD=up --force-recreate -d $(APPS)
reup: dc

dc:
	@>&2 echo "Running dc command: $(CMD)"
	@>&2 echo "Dcape URL: $(DCAPE_SCHEME)://$(DCAPE_HOST)"
	@>&2 echo "------------------------------------------"
	@docker compose $(DC_ARG_SRC) \
	  -p $$DCAPE_TAG --project-directory $$PWD \
	  $(CMD)

else

up: CMD=up -d
up: dc

reup: CMD=up --force-recreate -d
reup: dc

dc:
	docker compose -f $(DCAPE_ROOT)/apps/core/docker-compose.yml -f docker-compose.yml \
  --project-directory $$PWD \
  $(CMD)

endif

## stop (and remove) container(s)
down: CMD=down
down: dc

# ------------------------------------------------------------------------------
# DB operations

PGDATABASE      ?= $(APP_NAME)
PGUSER          ?= $(APP_NAME)
PGPASSWORD      ?= $(shell openssl rand -hex 16; echo)
PG_DUMP_SOURCE  ?=

ifeq ($(USE_DB),yes)

define CONFIG_DB

# ------------------------------------------------------------------------------
# Database name
PGDATABASE=$(PGDATABASE)
# Database user name
PGUSER=$(PGUSER)
# Database user password
PGPASSWORD=$(PGPASSWORD)
# Database dump for import on create
# Used as ${PG_DUMP_SOURCE}.{tar|tgz}
PG_DUMP_SOURCE=$(PG_DUMP_SOURCE)

endef
endif

# ------------------------------------------------------------------------------
## Database commands
#:

# Wait for postgresql container start
docker-wait:
	@echo -n "Checking PG is ready..." ; \
	until [[ `docker inspect -f "{{.State.Health.Status}}" $$PG_CONTAINER` == healthy ]] ; do sleep 1 ; echo -n "." ; done
	@echo "Ok"

# Database import script
# DCAPE_DB_DUMP_DEST must be set in pg container

define IMPORT_SCRIPT
[[ "$$DCAPE_DB_DUMP_DEST" ]] || { echo "DCAPE_DB_DUMP_DEST not set. Exiting" ; exit 1 ; } ; \
DB_NAME="$$1" ; DB_USER="$$2" ; DB_PASS="$$3" ; DB_SOURCE="$$4" ; \
dbsrc=$$DCAPE_DB_DUMP_DEST/$$DB_SOURCE ; \
if [ -f $${dbsrc}.tar ] ; then \
  echo "Prefer dump file $${dbsrc}.tar found, restoring database..." ; \
  PGPASSWORD=$$DB_PASS pg_restore -h localhost -U $$DB_USER -O -d $$DB_NAME $${dbsrc}.tar || exit 1 ; \
elif [ -f $${dbsrc}.tgz ] ; then \
  echo "Dump file $${dbsrc}.tgz found, restoring database..." ; \
  zcat $${dbsrc}.tgz | PGPASSWORD=$$DB_PASS pg_restore -h localhost -U $$DB_USER -O -Ft -d $$DB_NAME || exit 1 ; \
else \
  echo "Dump file $$dbsrc not found" ; \
  exit 2 ; \
fi
endef
export IMPORT_SCRIPT

## create database and user
db-create: docker-wait
	@echo "*** $@ ***" \
	&& varname=$(NAME)_DB_PASS && pass=$${!varname} \
	&& varname=$(NAME)_DB_TAG && dbname=$${!varname} \
	&& docker exec -i $$PG_CONTAINER psql -U postgres -c "CREATE USER \"$$dbname\" WITH PASSWORD '$$pass';" 2> >(grep -v "already exists" >&2) || true \
	&& docker exec -i $$PG_CONTAINER psql -U postgres -c "CREATE DATABASE \"$$dbname\" OWNER \"$$dbname\";" 2> >(grep -v "already exists" >&2) || db_exists=1 ; \
	if [[ ! "$$db_exists" ]] && [[ "$(PG_SOURCE_SUFFIX)" ]] ; then \
	    echo "$$IMPORT_SCRIPT" | docker exec -i $$PG_CONTAINER bash -s - $$dbname $$dbname $$pass $$dbname$(PG_SOURCE_SUFFIX) \
	    && docker exec -i $$PG_CONTAINER psql -U postgres -c "COMMENT ON DATABASE \"$$dbname\" IS 'SOURCE $$dbname$(PG_SOURCE_SUFFIX)';" \
	    || true ; \
	fi

## drop database and user
db-drop:
	@echo "*** $@ ***" \
	&& varname=$(NAME)_DB_TAG && dbname=$${!varname} \
	&& docker exec -i $$PG_CONTAINER psql -U postgres -c "DROP DATABASE \"$$dbname\";" \
	&& docker exec -i $$PG_CONTAINER psql -U postgres -c "DROP USER \"$$dbname\";"

## exec psql inside db container
psql:
	@docker exec -it $$PG_CONTAINER psql -U postgres

## run local psql
## (requires pg client installed)
psql-local:
	@psql postgresql://postgres:$(PG_DB_PASS)@localhost:$(PG_PORT_LOCAL)/postgres?sslmode=disable

# ------------------------------------------------------------------------------
## App config storage commands
#:

## get env tag from store, `make env-get TAG=app--config--tag`
env-get:
	@[[ "$(TAG)" ]] || { echo "Error: Tag value required" ; exit 1 ;}
	@echo "Getting env into $(TAG)"
	@docker run --rm -i --network $${DCAPE_NET} $${DCAPE_TAG}_drone-compose curl -gs $${ENFIST_URL}/tag_vars?code=$(TAG) \
	  | jq -r '.' > $(TAG).env

## list env tags in store
env-ls:
	@docker run --rm -i --network $${DCAPE_NET} $${DCAPE_TAG}_drone-compose curl -gs $${ENFIST_URL}/tag \
	  | jq -r '.[] | .updated_at +"  "+.code'

## set env tag in store, `make env-set TAG=app--config--tag`
env-set:
	@[[ "$(TAG)" ]] || { echo "Error: Tag value required" ; exit 1 ;}
	@echo "Setting $(TAG) from file" \
	&& jq -R -sc ". | {\"code\":\"$(TAG)\",\"data\":.}" < $(TAG).env | \
	  docker run --rm -i --network $${DCAPE_NET} $${DCAPE_TAG}_drone-compose curl -gsd @- $${ENFIST_URL}/tag_set > /dev/null


# ------------------------------------------------------------------------------
## .env operations
#:

# This code generates $(CFG).sample from Makefile vars with previous comment line(s)
# See https://gist.github.com/LeKovr/2697fe02504d7c081b0bf79427c93db6

# Internal: generate config sample data
.env.temp.mk:
	@echo "define CFVAR" > $@
	@grep -A 1 -h "^#- " $(MAKEFILE_LIST) | grep -vE "^--" \
	  | sed -E 's/^([^\n ]+)\ *\??=([^\n]*)$$/\1=$$(\1)\n/ ; s/^(#)-/\1/' >> $@
	@echo "endef" >> $@

ifneq ($(findstring $(MAKECMDGOALS),config config-force config-if $(CFG).sample),)
include .env.temp.mk
endif

# Internal: generate config sample
$(CFG).sample: .env.temp.mk
	@echo -e "# dcape config file, generated by 'make $(MAKECMDGOALS)'\n" > $@
	@echo "$$CFVAR" >> $@
	@echo "$$CONFIG_DEF$$CONFIG_DB$$CONFIG_USER$$CONFIG_CUSTOM" >> $@
	@rm -f $<

## generate sample config
config: $(CFG).sample

## generate sample config and rename it to .env
config-force: config
	@mv $(CFG).sample $(CFG)

## generate sample config and rename it to .env if not exists
config-if: config
	@[ -f $(CFG) ] || mv $(CFG).sample $(CFG)

# ------------------------------------------------------------------------------
## Other
#:

## delete unused docker images w/o name
## (you should use portainer for this)
clean-noname:
	@docker images | grep -q "<none>" && docker rmi $$(docker images | grep "<none>" | awk "{print \$$3}") || echo "None found"

## delete docker dangling volumes
## (you should use portainer for this)
clean-volume:
	@vols=$$(docker volume ls -qf dangling=true) ; \
	[ $$vols ] && docker volume rm $$vols || echo "None found"

# This code handles group header and target comment with one or two lines only
## list Makefile targets
## (this is default target)
help:
	@grep -A 1 -h "^## " $(MAKEFILE_LIST) \
  | sed -E 's/^--$$// ; /./{H;$$!d} ; x ; s/^\n## ([^\n]+)\n(## (.+)\n)*(.+):(.*)$$/"    " "\4" "\1" "\3"/' \
  | sed -E 's/^"    " "#" "(.+)" "(.*)"$$/"" "" "" ""\n"\1 \2" "" "" ""/' \
  | xargs printf "%s\033[36m%-15s\033[0m %s %s\n"