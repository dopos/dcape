ARG DC_VER

FROM docker/compose:$DC_VER

MAINTAINER Alexey Kovrizhkin <lekovr+dopos@gmail.com>

ENV DOCKERFILE_VERSION  20201130

RUN apk add --no-cache curl git make jq

COPY setup /usr/local/bin/
COPY dcape-app /opt/dcape-app

ARG DRONE_ROOT
LABEL dcape_app_makefile $DRONE_ROOT/dcape-app/Makefile
