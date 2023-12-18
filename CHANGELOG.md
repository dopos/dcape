# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [3.0.2] - 2023-12-18

## Added

* docs: [Upgrade dcape v2 to v3](upgrade_v2.md)
* [CHANGELOG.md](CHANGELOG.md)
* DCAPE_NET_EXISTS
* DB_CONTAINER for apps
* ENFIST_BRANCH
* APP_ROOT_OPTS, .build

## Fixes

* fix: host mount for cicd deploy
* not use .env in build
* fix: psql-local for app
* upd: dev.lan -> dev.test
* upd: Serve flow
* .default-deploy improved

### Upgrade

```
$ make config-if
$ mv .dcape.env.sample .dcape.env
# set DCAPE_NET_EXISTS=true
$ make .env
```

## [3.0.1] - 2023-12-09

### Changes

* fix: host mount for cicd deploy
* fix: psql-local for app
* fix: grep .env if var not global

* upd: upgrade-v3, docs
* upd: dev.lan -> dev.test

### Upgrade

```sh
make git-pull APPS=cicd
git pull
make docker-compose.yml
make build-compose
make up

```
