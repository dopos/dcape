# Gitea init Makefile
# This file included by ../../Makefile
SHELL               = /bin/bash
# Default docker image version
GITEA_VER0         ?= 1.15.5
# Config vars are described below in section `define CONFIG_...`
GITEA_HOST         ?= git.$(DCAPE_DOMAIN)
GITEA_SSH_PORT     ?= 10022
GITEA_DB_TAG       ?= gitea
GITEA_DB_PASS      ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 2>/dev/null | head -c14; echo)
GITEA_VER          ?= $(GITEA_VER0)

define CONFIG_GITEA
# ==============================================================================
# Gitea: general config

# Gitea hostname
GITEA_HOST=$(GITEA_HOST)

# Gitea ssh server port
# You should change sshd port and set this to 22
GITEA_SSH_PORT=$(GITEA_SSH_PORT)

# ------------------------------------------------------------------------------
# Gitea: internal config

# Database name and database user name
GITEA_DB_TAG=$(GITEA_DB_TAG)

# Database user password
GITEA_DB_PASS=$(GITEA_DB_PASS)

# Gitea Docker image version
GITEA_VER=$(GITEA_VER)

endef
export CONFIG_GITEA

# ------------------------------------------------------------------------------

# Init data for $(DCAPE_VAR)/gitea/gitea/conf/app.ini
define INI_GITEA
APP_NAME = Gitea: Git with a cup of tea
RUN_USER = git
RUN_MODE = prod

[server]
SSH_DOMAIN = $(GITEA_HOST)
DOMAIN     = $(GITEA_HOST)
ROOT_URL   = $(DCAPE_SCHEME)://$(GITEA_HOST)/

[database]
DB_TYPE  = postgres
HOST     = db:5432
NAME     = $(GITEA_DB_TAG)
USER     = $(GITEA_DB_TAG)
SSL_MODE = disable
PASSWD   = $(GITEA_DB_PASS)

[mailer]
ENABLED = false

[service]
REGISTER_EMAIL_CONFIRM            = false
ENABLE_NOTIFY_MAIL                = false
DISABLE_REGISTRATION              = false
ALLOW_ONLY_EXTERNAL_REGISTRATION  = false
ENABLE_CAPTCHA                    = false
REQUIRE_SIGNIN_VIEW               = false
DEFAULT_KEEP_EMAIL_PRIVATE        = false
DEFAULT_ALLOW_CREATE_ORGANIZATION = true
DEFAULT_ENABLE_TIMETRACKING       = true
NO_REPLY_ADDRESS                  = noreply.$(DOMAIN)

[picture]
DISABLE_GRAVATAR        = false
ENABLE_FEDERATED_AVATAR = true

[openid]
ENABLE_OPENID_SIGNIN = true
ENABLE_OPENID_SIGNUP = true

[session]
PROVIDER = file

endef
export INI_GITEA

# ------------------------------------------------------------------------------

gitea-init:
	@grep GITEA_DB_PASS $(CFG) || \
	{ \
	  echo "$$CONFIG_GITEA" >> $(CFG) ; \
	}
	@if [[ "$$GITEA_VER0" != "$$GITEA_VER" ]] ; then \
	  echo "Warning: GITEA_VER in dcape ($$GITEA_VER0) differs from yours ($$GITEA_VER)" ; \
	fi
	@echo "  URL: $(DCAPE_SCHEME)://$(GITEA_HOST)"
	@echo "  SSH port: $(GITEA_SSH_PORT)"

gitea-apply: $(DCAPE_VAR)/gitea/gitea/conf $(DCAPE_VAR)/gitea/gitea/conf/app.ini
	@$(MAKE) -s db-create NAME=GITEA

$(DCAPE_VAR)/gitea/gitea/conf:
	@mkdir -p $@

$(DCAPE_VAR)/gitea/gitea/conf/app.ini:
	@echo "$$INI_GITEA" > $@
	@chmod 666 $@
