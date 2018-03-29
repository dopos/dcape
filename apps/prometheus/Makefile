# Prometheus init Makefile
# This file included by ../../Makefile

SHELL			= /bin/bash

# DCAPE_USED==1 when called from upper Makefile
DCAPE_USED		?= 0 
# Prometheus Docker image version by dcape
PROMETHEUS_VER0		?= v2.1.0
# Prometheus Docker image version
PROMETHEUS_VER		?= $(PROMETHEUS_VER0)
# Prometheus hostname prefix
PROMETHEUS_HOST_PREFIX	= prom5s
# Prometheus hostname
PROMETHEUS_HOST		?= $(PROMETHEUS_HOST_PREFIX).$(DOMAIN)

define CONFIG_PROMETHEUS
#---------------------------------------------------------------------------
# Prometheus settings

# Docker image version
PROMETHEUS_VER=$(PROMETHEUS_VER)

#App hostname
PROMETHEUS_HOST=$(PROMETHEUS_HOST)

endef
export CONFIG_PROMETHEUS

prometheus-init:
	@grep PROMETHEUS_ .env > /dev/null || echo "$$CONFIG_PROMETHEUS" >> .env
	@if [[ "$$PROMETHEUS_VER0" != "$$PROMETHEUS_VER" ]] ; then \
	  echo "Warning: PROMETHEUS_VER in dcape ($$PROMETHEUS_VER0) differs from yours ($$PROMETHEUS_VER)" ; \
	fi

prometheus-apply: 
