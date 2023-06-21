# Gitea init Makefile
# This file included by ../../Makefile
SHELL               = /bin/bash
# Docker image and version tested for actual dcape release
GITEA_IMAGE0       ?= gitea/gitea
GITEA_VER0         ?= 1.19.1

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
GITEA_DB_PASS      ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 2>/dev/null | head -c14; echo)
#- Gitea Docker image
GITEA_IMAGE        ?= $(GITEA_IMAGE0)
#- Gitea Docker image version
GITEA_VER          ?= $(GITEA_VER0)

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

[metrics]
ENABLED=true
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
	@if [[ "$$GITEA_IMAGE0" != "$$GITEA_IMAGE" ]] ; then \
	  echo "Warning: GITEA_IMAGE in dcape ($$GITEA_IMAGE0) differs from yours ($$GITEA_IMAGE)" ; \
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

# ------------------------------------------------------------------------------
# setup gitea objects

GITEA_ORG_CREATE_URL = $(AUTH_SERVER)/api/v1/admin/users/$(DRONE_ADMIN)/orgs
APP_CREATE_URL       = $(AUTH_SERVER)/api/v1/user/applications/oauth2

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
  "redirect_uris": [ "$(DCAPE_SCHEME)://$(DCAPE_HOST)/login" ]
}
endef

define DRONE_APP_CREATE
{
  "name": "$(DRONE_HOST)",
  "redirect_uris": [ "$(DCAPE_SCHEME)://$(DRONE_HOST)/login" ]
}
endef

define POST_CMD
 -H "Accept: application/json" \
 -H "Content-Type: application/json" \
 -H "Authorization: token $(TOKEN)"
endef

## create gitea org and oauth2 applications
gitea-setup:
	@echo "*** $@ ***"
	@if [[ -z "$(TOKEN)" ]] ; then echo >&2 "TOKEN arg must be defined" ; false ; fi
	@echo "Auth server: $(AUTH_SERVER)"
	@echo "Drone admin: $(DRONE_ADMIN)"
	@echo "Gitea org:   $(NARRA_GITEA_ORG)"
	@echo "Token:       $(TOKEN)"
	@echo -n "create org... " ; \
if resp=$$(echo $$GITEA_ORG_CREATE | curl -gsS -X POST $(GITEA_ORG_CREATE_URL) $(POST_CMD) -d @-) ; then \
  if echo $$resp | jq -re '.id' > /dev/null ; then \
    echo "Done" ; \
  else \
    echo -n "Server response: " ; \
    echo $$resp | jq -re '.message' ; \
  fi ; \
else false ; fi
	@echo -n "create narra app..." ; \
if resp=$$(echo $$NARRA_APP_CREATE | curl -gsS -X POST $(APP_CREATE_URL) $(POST_CMD) -d @-) ; then \
  client_id=$$(echo $$resp | jq -r '.client_id') ; \
  client_secret=$$(echo $$resp | jq -r '.client_secret') ; \
  sed -i "s/=NARRA_CLIENT_ID=/$$client_id/ ; s/=NARRA_CLIENT_KEY=/$$client_secret/ " $(CFG) ; \
  echo "Done" ; \
else false ; fi
	@echo -n "create drone app..." ; \
if resp=$$(echo $$DRONE_APP_CREATE | curl -gsS -X POST $(APP_CREATE_URL) $(POST_CMD) -d @-) ; then \
  client_id=$$(echo $$resp | jq -r '.client_id') ; \
  client_secret=$$(echo $$resp | jq -r '.client_secret') ; \
  sed -i "s/=DRONE_CLIENT_ID=/$$client_id/ ; s/=DRONE_CLIENT_KEY=/$$client_secret/ " $(CFG) ; \
  echo "Done" ; \
else false ; fi
	@echo "Gitea setup complete, do reup"
