FROM ghcr.io/dopos/docker-alpine:v3.14.3

MAINTAINER Alexey Kovrizhkin <lekovr+dopos@gmail.com>

ENV DOCKERFILE_VERSION  20211117

RUN apk add --no-cache curl git make jq docker-compose

COPY setup /usr/local/bin/
COPY dcape-app /opt/dcape-app

ARG DRONE_ROOT
LABEL dcape_app_makefile $DRONE_ROOT/dcape-app/Makefile

ENTRYPOINT ["docker-compose"]
