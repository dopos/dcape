# Gitea init Makefile
# This file included by ../../Makefile
SHELL               = /bin/bash
# Docker image and version tested for actual dcape release
GITEA_IMAGE0       ?= gitea/gitea
GITEA_VER0         ?= 1.19.3

#- ******************************************************************************
#- Gitea: general config

#- Gitea hostname
GITEA_HOST         ?= git.$(DCAPE_DOMAIN)
#- Gitea ssh server port
#- You should change sshd port and set this to 22
GITEA_SSH_PORT     ?= 10022

#- ------------------------------------------------------------------------------
#- Gitea: internal config

#- Database name and database user name
GITEA_DB_TAG       ?= gitea
#- Database user password
GITEA_DB_PASS      ?= $(shell openssl rand -hex 16; echo)
#- Gitea Docker image
GITEA_IMAGE        ?= $(GITEA_IMAGE0)
#- Gitea Docker image version
GITEA_VER          ?= $(GITEA_VER0)

#- Gitea admin user name
GITEA_ADMIN_NAME   ?= dcapeadmin
#- Gitea admin user email
GITEA_ADMIN_EMAIL  ?= $(GITEA_ADMIN_NAME)@$(DCAPE_DOMAIN)
#- Gitea admin user password
GITEA_ADMIN_PASS   ?= $(shell openssl rand -hex 16; echo)

#- Gitea mailer enabled
GITEA_MAILER_ENABLED   ?= false
#- Gitea mailer ip
GITEA_MAILER_ADDR     ?=
#- Gitea mailer port
GITEA_MAILER_PORT     ?=
#- Gitea mailer sender email
GITEA_MAILER_FROM     ?=
#- Gitea mailer user
GITEA_MAILER_USER     ?=
#- Gitea mailer password
GITEA_MAILER_PASS     ?=


#make dc CMD="run gitea gitea generate secret INTERNAL_TOKEN"

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

[security]
INSTALL_LOCK   = true

[picture]
DISABLE_GRAVATAR        = false
ENABLE_FEDERATED_AVATAR = true

[openid]
ENABLE_OPENID_SIGNIN = true
ENABLE_OPENID_SIGNUP = true

[session]
PROVIDER = file

[metrics]
ENABLED=true
endef
export INI_GITEA

# ------------------------------------------------------------------------------

gitea-init:
	@if [[ "$$GITEA_VER0" != "$$GITEA_VER" ]] ; then \
	  echo "Warning: GITEA_VER in dcape ($$GITEA_VER0) differs from yours ($$GITEA_VER)" ; \
	fi
	@if [[ "$$GITEA_IMAGE0" != "$$GITEA_IMAGE" ]] ; then \
	  echo "Warning: GITEA_IMAGE in dcape ($$GITEA_IMAGE0) differs from yours ($$GITEA_IMAGE)" ; \
	fi
	@echo "  URL: $(AUTH_SERVER)"
	@echo "  SSH port: $(GITEA_SSH_PORT)"

gitea-apply: $(DCAPE_VAR)/gitea-app-data $(DCAPE_VAR)/gitea/gitea/conf/app.ini
	@$(MAKE) -s db-create NAME=GITEA

$(DCAPE_VAR)/gitea/gitea/conf/app.ini: $(DCAPE_VAR)/gitea/gitea/conf
	@echo "$$INI_GITEA" > $@
	@chown 1000:1000 $@

$(DCAPE_VAR)/gitea/gitea/conf:
	@mkdir -p $@
	@chown -R 1000:1000 $@

$(DCAPE_VAR)/gitea-app-data:
	@mkdir -p $@
	@chown 1000:1000 $@


# ------------------------------------------------------------------------------
# setup gitea objects

GITEA_CREATE_TOKEN_URL = $(AUTH_SERVER)/api/v1/users/$(GITEA_ADMIN_NAME)/tokens
GITEA_ORG_CREATE_URL = $(AUTH_SERVER)/api/v1/admin/users/$(GITEA_ADMIN_NAME)/orgs
APP_CREATE_URL       = $(AUTH_SERVER)/api/v1/user/applications/oauth2



gitea-admin:
	@$(MAKE) -s dc CMD="exec gitea su git -c 'gitea admin user create --admin --username $(GITEA_ADMIN_NAME) --password $(GITEA_ADMIN_PASS) --email $(GITEA_ADMIN_EMAIL)'"


define GITEA_ORG_CREATE
{
  "username": "$(NARRA_GITEA_ORG)",
  "visibility": "limited",
  "repo_admin_change_team_access": true
}
endef

define NARRA_APP_CREATE
{
  "name": "$(DCAPE_HOST)",
  "confidential_client": true,
  "redirect_uris": [ "$(DCAPE_SCHEME)://$(DCAPE_HOST)/login" ]
}
endef

define CICD_APP_CREATE
{
  "name": "$(CICD_HOST)",
  "confidential_client": true,
  "redirect_uris": [ "$(DCAPE_SCHEME)://$(CICD_HOST)/authorize" ]
}
endef

define POST_CMD
 -H "Accept: application/json" \
 -H "Content-Type: application/json" \
 -H "Sudo: $(NARRA_GITEA_ORG)" \
 -H "Authorization: token $(TOKEN)"
endef

TOKEN_NAME ?= install

# sudo - create org
# write:application - create application

define GITEA_TOKEN_CREATE
{
  "name": "$(TOKEN_NAME)",
  "scopes": ["sudo", "write:application"]
}
endef

ifeq ($(TOKEN),)
gitea-setup: token-fetch
else
gitea-setup: token-use
endif

token-fetch:
	@echo -n "create token... " ; \
	if resp=$$(echo $$GITEA_TOKEN_CREATE | curl -gsS -X POST -d @- -H "Content-Type: application/json" -u "$(GITEA_ADMIN_NAME):$(GITEA_ADMIN_PASS)" $(GITEA_CREATE_TOKEN_URL)) ; then \
	  if token=$$(echo $$resp | jq -re '.sha1') ; then \
	    echo "Token $$token: Done" ; \
	  else \
	    echo -n "ERROR: " ; \
	    echo $$resp | jq -re '.' ; \
	  fi ; \
	else false ; fi ; \
	$(MAKE) -s token-use TOKEN=$$token ; \
	echo -n "remove token... " ; \
	if resp=$$(curl -gsS -X DELETE -u "$(GITEA_ADMIN_NAME):$(GITEA_ADMIN_PASS)" $(GITEA_CREATE_TOKEN_URL)/$(TOKEN_NAME)) ; then \
	  if [[ -z $$resp ]] ; then \
	    echo "Done" ; \
	  else \
	    echo -n "ERROR: " ; \
	    echo $$resp | jq -re '.message' ; \
	  fi ; \
	else false ; fi

## create gitea org and oauth2 applications
token-use:
	@echo "*** $@ ***"
	@if [[ -z "$(TOKEN)" ]] ; then echo >&2 "TOKEN arg must be defined" ; false ; fi
	@echo "Auth server: $(AUTH_SERVER)"
	@echo "CICD admin:  $(CICD_ADMIN)"
	@echo "Gitea org:   $(NARRA_GITEA_ORG)"
	@echo "Token:       $(TOKEN)"
	@echo -n "create org... " ; \
	if resp=$$(echo $$GITEA_ORG_CREATE | curl -gsS -X POST $(GITEA_ORG_CREATE_URL) $(POST_CMD) -d @-) ; then \
	  if echo $$resp | jq -re '.id' > /dev/null ; then \
	    echo "Org $(NARRA_GITEA_ORG): Done" ; \
	  else \
	    echo -n "ERROR: " ; \
	    echo $$resp | jq -re '.message' ; \
	  fi ; \
	else false ; fi
	@echo -n "create narra app..." ; \
	if resp=$$(echo $$NARRA_APP_CREATE | curl -gsS -X POST $(APP_CREATE_URL) $(POST_CMD) -d @-) ; then \
	  client_id=$$(echo $$resp | jq -r '.client_id') ; \
	  client_secret=$$(echo $$resp | jq -r '.client_secret') ; \
	  sed -i "s/SET_NARRA_CLIENT_ID_HERE/$$client_id/ ; s/SET_NARRA_CLIENT_SECRET_HERE/$$client_secret/ " $(CFG) ; \
	  echo " Done" ; \
	else false ; fi
	@echo -n "create CICD app..." ; \
	if resp=$$(echo $$CICD_APP_CREATE | curl -gsS -X POST $(APP_CREATE_URL) $(POST_CMD) -d @-) ; then \
	  client_id=$$(echo $$resp | jq -r '.client_id') ; \
	  client_secret=$$(echo $$resp | jq -r '.client_secret') ; \
	  sed -i "s/SET_GITEA_CLIENT_ID_HERE/$$client_id/ ; s/SET_GITEA_CLIENT_SECRET_HERE/$$client_secret/ " $(CFG) ; \
	  echo " Done" ; \
	else false ; fi
	@echo "Gitea setup complete, do reup"
