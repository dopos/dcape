SHELL = /bin/bash
DCAPE_USED ?= 0

define CONFIG_DRONE
# ------------------------------------------------------------------------------
# Drone settings

# App hostname
DRONE_HOST=drone.$(DOMAIN)

DRONE_SECRET=change_me

DRONE_GIT_URL=http://git.$(DOMAIN)/

# логин пользователя gitea с правами админа в drone
DRONE_ADMIN=admin

DRONE_DB_PASS=change_me

endef
export CONFIG_DRONE

drone-init:
	@echo "$$CONFIG_DRONE" >> .env

drone-apply:
	@$(MAKE) -s db-create NAME=drone


