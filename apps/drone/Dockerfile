ARG DC_VER

FROM docker/compose:$DC_VER

MAINTAINER Alexey Kovrizhkin <lekovr+dopos@gmail.com>

ENV DOCKERFILE_VERSION  20201130

RUN apk add --no-cache curl git make jq

COPY setup /usr/local/bin/
