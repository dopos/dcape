SHELL = /bin/bash
DCAPE_USED ?= 0
SSH_KEY_NAME ?= hook

define CONFIG_CIS
# ------------------------------------------------------------------------------
# CI site settings

# App hostname
CIS_HOST=cis.$(DOMAIN)

# Private admin site part (traefik, consul, webtail, dns)
CIS_AREA_LOGIN=admin
CIS_AREA_PASS=change_me

endef
export CONFIG_CIS


# Init data for $${GITEA_INI_DIR}/app.ini
define JSON_CIS
var services = {
  "gitea": "$(GITEA_HOST)",
  "mmost": "$(MMOST_HOST)",
  "drone": "$(DRONE_HOST)",
  "port":  "$(PORTAINER_HOST)"
};
endef
export JSON_CIS


cis-init:
	@echo "$$CONFIG_CIS" >> .env

cis-apply: var/data/cis var/data/cis/htpasswd var/data/cis/html/$(SSH_KEY_NAME).pub
	@echo "*** $@ ***"

var/data/cis:
	@[ -d var/data/cis ] || mkdir var/data/cis
	@cp -pr apps/cis/{nginx.conf,html,hooks} var/data/cis
	echo "$$JSON_CIS" > var/data/cis/html/services.json

var/data/cis/htpasswd:
	@P=$$(echo $$CIS_AREA_PASS | openssl passwd -stdin) && echo "$$CIS_AREA_LOGIN:$$P" > var/data/cis/htpasswd

var/data/cis/html/$(SSH_KEY_NAME).pub:
	ssh-keygen -t rsa -b 4096 -f $(SSH_KEY_NAME) -N "" -C webhook@$$DOMAIN
	@mv $(SSH_KEY_NAME) var/data/cis/hooks/
	@mv $(SSH_KEY_NAME).pub var/data/cis/html/
