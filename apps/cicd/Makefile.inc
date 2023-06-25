# woodpecker init Makefile
# This file included by ../../Makefile

# Docker image version tested for actual dcape release
CICD_VER0        ?= v0.15.9-alpine

#- ******************************************************************************
#- CICD: general config

#- CICD hostname
CICD_HOST          ?= cicd.$(DCAPE_DOMAIN)

#- CICD admin user
CICD_ADMIN         ?= $(GITEA_ADMIN_NAME)

#- VCS (Version control systems) (gitea/github) config

#- Use GitHub
CICD_GITHUB_USED   ?= false
#- Github URL for auth and repos
CICD_GITHUB_URL    ?= http://git.dev.lan
#- Github client ID
CICD_GITHUB_CLIENT ?= SET_GITHUB_CLIENT_ID_HERE
#- Github client secret
CICD_GITHUB_SECRET ?= SET_GITHUB_CLIENT_SECRET_HERE

#- Use Gitea
CICD_GITEA_USED    ?= true
#- Gitea URL for auth and repos
CICD_GITEA_URL     ?= $(AUTH_SERVER)
#- Gitea client ID
CICD_GITEA_CLIENT  ?= SET_GITEA_CLIENT_ID_HERE
#- Gitea client secret
CICD_GITEA_SECRET  ?= SET_GITEA_CLIENT_SECRET_HERE

#- ------------------------------------------------------------------------------
#- CICD: internal config

#- Database name and database user name
CICD_DB_TAG        ?= cicd
#- Database user password
CICD_DB_PASS       ?= $(shell openssl rand -hex 16; echo)

#- Agent secret
CICD_AGENT_SECRET  ?= $(shell openssl rand -hex 32; echo)

#- Docker repo & image name without version
CICD_IMAGE         ?= woodpeckerci/woodpecker-server
#- Docker image version
CICD_VER           ?= $(CICD_VER0)

# add config to $(CFG)
cicd-init:
	@if [[ "$$CICD_VER0" != "$$CICD_VER" ]] ; then \
	  echo "Warning: CICD_VER in dcape ($$CICD_VER0) differs from yours ($$CICD_VER)" ; \
	fi
	@echo "  URL: $(DCAPE_SCHEME)://$(CICD_HOST)"
	@echo "  Admin: $(CICD_ADMIN)"

# create DB
cicd-apply:
	@cmd=create ; \
	$(MAKE) -s db-create NAME=CICD
