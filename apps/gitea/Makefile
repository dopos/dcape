SHELL = /bin/bash
DCAPE_USED ?= 0

define CONFIG_GITEA
# ------------------------------------------------------------------------------
# Gitea settings

# App hostname
GITEA_HOST=git.$(DOMAIN)

GITEA_DB_PASS=change_me

endef
export CONFIG_GITEA

GITEA_INI_DIR ?= var/data/gitea/gitea/conf

# Init data for $${GITEA_INI_DIR}/app.ini
define INI_GITEA
[server]
SSH_DOMAIN       = $(GITEA_HOST)
DOMAIN           = $(GITEA_HOST)
ROOT_URL         = http://$(GITEA_HOST)/

[database]
DB_TYPE = postgres
HOST = db:5432
NAME = gitea
USER = gitea
SSL_MODE = disable

[log]
ROOT_PATH = /data/log
endef
export INI_GITEA


gitea-init:
	@echo "$$CONFIG_GITEA" >> .env


gitea-apply:
	@$(MAKE) -s db-create NAME=gitea
	@[ -d $$GITEA_INI_DIR ] || mkdir -p $$GITEA_INI_DIR
	@[ -f $$GITEA_INI_DIR/app.ini ] || echo "$$INI_GITEA" > $$GITEA_INI_DIR/app.ini
	@[ -d var/log/gitea ] || mkdir -p var/log/gitea
	@chown 1000 var/log/gitea $$GITEA_INI_DIR/app.ini
