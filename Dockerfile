FROM docker:29.0.0

#ghcr.io/dopos/docker-alpine:v3.14.3

ENV DOCKERFILE_VERSION=20250402

RUN apk add --no-cache curl git make jq bash

RUN mkdir /opt/dcape
COPY Makefile.common Makefile.app  docker-compose.app.yml /opt/dcape/
ENV DCAPE_ROOT=/opt/dcape

ARG DCAPE_HOST_ROOT
LABEL dcape_root=$DCAPE_HOST_ROOT
# LABEL MAINTAINER Alexey Kovrizhkin <lekovr+dopos@gmail.com>

#ENTRYPOINT ["docker-compose"]
