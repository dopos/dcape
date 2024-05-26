# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [3.1.0] - 2024-05-27

### Added

* compare local app versions with upstream & update local (make ver-cmp [ VER_UPDATE=yes])
* debug for gitea exchange (including POST debug)

### Fixed

* APPS recurse
* CICD_ADMIN
* empty AUTH_URL, DCAPE_ADMIN_USER
* read APP_ROOT from .env
* standalone .config-link
* 'version' is obsolete
* copyright years

## [3.0.2] - 2023-12-18

### Added

* docs: [Upgrade dcape v2 to v3](upgrade_v2.md)
* [CHANGELOG.md](CHANGELOG.md)
* DCAPE_NET_EXISTS
* DB_CONTAINER for apps
* ENFIST_BRANCH
* APP_ROOT_OPTS, .build

### Fixed

* host mount for cicd deploy
* not use .env in build
* psql-local for app
* dev.lan -> dev.test
* improve Serve flow
* .default-deploy improved
* host mount for cicd deploy
* psql-local for app
* grep .env if var not global

* upd: upgrade-v3, docs
* upd: dev.lan -> dev.test

### Upgrade

```
git pull
make git-pull
make config-if
mv .dcape.env.sample .dcape.env
set DCAPE_NET_EXISTS=true
make .env
make build-compose
make up
```

## [3.0.0] - 2023-08-01

### Changed

* Move to docker compose plugin
* Replaced drone with woodpecker
* Separated core apps repos and configs, see [dcape3-coreapp](https://github.com/topics/dcape3-coreapp)
* Improve [dcape-app](https://github.com/topics/dcape3-app)

## [2.2.1] - 2023-06-21

### Fixed

* set HTTP_PROTO after include
* add PG_ADMIN var
* rm double labels
* add timezone
* psql-local via DSN

## [2.1.2] - 2022-03-30

Bump docker images:

* traefik:2.6.2
* gitea/gitea:1.16.5
* drone/drone:2.11.1
* drone/drone-runner-docker:1.8.0
* portainer/portainer-ce:2.11.1-alpine
* ghcr.io/dopos/powerdns-alpine:v4.6.1

## [2.1.1] - 2021-11-27

### Fixed

* drone pipelines for non-amd64 drone runners
* postgresql backups: try .tar before .tgz
* support for docker-compose v1.28+

### Upgrade

```
git pull
mv .env .env.bak
make init
make up
```

## [2.1.0] - 2021-11-17

### Added

* own docker images placed at ghcr.io
* support for arm64 arch
* updated third-party apps versions

## [2.0.0] - 2021-01-28

* own docker images placed at ghcr.io
* added support for arm64 arch
* updated third-party apps versions

## [1.1] - 2020-11-16

* 2 years in prod

## [1.0.0-rc2] - 2018-09-23

### Изменено

* apps/enfist: вместо pgrpc-sql-enfist теперь используется [apisite](https://github.com/apisite/app-enfist)

### Установка обновления

```bash
git pull
mv .env .env.bak
make init
make enfist-apply
make up
```

## [1.0.0-rc1] - 2017-10-22

### Изменено

* apps/traefik*: в настройки вынесен редирект 80 -> 443
* apps/traefik теперь не совместим по конфигу с apps/traefik-acme, при переключении необходим `make init`
* apps/cis: добавлено создание каталогов var/apps, var/log в cis-apply
* apps/cis: изменена версия webtail (0.12)
* apps/enfist: исправлено обновление sql-пакетов enfist,rpc и их текущие версии

### Добавлено

* Файл CHANGELOG.md
* README.md: информация о зависимости (gawk), уточнен блок "Быстрый старт"
* DEPLOY.md: блоки "Информация для разработчика", "Удаление деплоя"
* Makefile: поддержка параметров `PG_PORT_LOCAL`, `CFG_BAK`

### Установка обновления

```bash
git pull
mv .env .env.bak

make init
# Тут будет предупреждение об устаревшей версии webtail - надо изменить на новую в .env

make enfist-apply
# Сообщения "ERROR:  Newest lib version (0.1) loaded already" игнорируем, других ошибок быть не должно

make dc CMD="up -d webtail"
```

## [0.1] - 2017-08-11

Move to dcape project, code working in general, [commit](https://github.com/dopos/dcape/commit/6bf1f5f8f2e408e3ef492ef35dc50ce31620491d)

## [0.0.2] - 2015-02-12

* Github: [fidm](https://github.com/LeKovr/fidm)
* Commit: [init](https://github.com/LeKovr/fidm/commit/e2afd7dfe279a2240ab4283268b3404500f5c4c5)
* Last commit: 2018-08-15

Начало разработки аналога **fig**, утилиты для управления контейнерами Docker, которая была доступна на сайте [fig.sh](http://fig.sh).

## [0.0.1] - 2014-11-12

* Github: [consup](https://github.com/LeKovr/consup)
* Commit: [init](https://github.com/LeKovr/consup/commit/0decc256f3ae5c6ae057c398105f0e1ec20dc591)
* Last commit: 2017-09-27

Начало работ по построению решения для автоматизации использования контейнеров docker.
