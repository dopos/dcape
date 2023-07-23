<p align="center">
  <a href="README.md#readme">English</a> |
  <span>Pусский</span>
</p>

---

# dopos/dcape

> Среда управления docker-приложениями

[![GitHub Release][1]][2]
![GitHub code size in bytes][3]
[![GitHub license][4]][5]

[1]: https://img.shields.io/github/release/dopos/dcape.svg
[2]: https://github.com/dopos/dcape/releases
[3]: https://img.shields.io/github/languages/code-size/dopos/dcape.svg
[4]: https://img.shields.io/github/license/dopos/dcape.svg
[5]: LICENSE

[Dcape](https://github.com/dopos/dcape) - это инструмент создания окружения (среды) для развёртывания [docker](https://www.docker.com/)-приложений по технологии [GitOps](https://www.gitops.tech/), который с помощью [make](https://www.gnu.org/software/make/) и [docker-compose](https://docs.docker.com/compose/), позволяет решить следующие задачи:

* командами `make up` запускать приложения, использующие
  * **общий порт** (например 80)
  * **БД**
* командой `git push` **удаленно разворачивать приложения** на одном или нескольких компьютерах
* через АПИ или web-интерфейс **управлять конфигурациями** приложений
* **ограничивать** заданной группой пользователей **доступ** к интерфейсам управления используемым ПО
* обслуживать работу с letsencrypt сертификатами **wildcard-доменов**
* **управлять инфраструктурой docker**

## Приложения

Для решения этих задач в **dcape** используются docker-образы следующих приложений:

* **общий порт**  - [traefik](https://traefik.io/)
  * **БД** - [postgresql](https://www.postgresql.org)
* **удаленно разворачивать приложения** - [drone](https://github.com/drone) (на каждом компьютере) и на каком-то одном - [gitea](https://gitea.io/) (или аналог)
* **управлять конфигурациями** - [enfist](https://github.com/apisite/app-enfist)
* **ограничивать доступ** - [narra](https://github.com/dopos/narra), в качестве группы пользователей используется организация [gitea](https://gitea.io/)
* **wildcard-домены** - [powerdns](https://www.powerdns.com/)
* **управлять инфраструктурой docker** - [portainer](https://portainer.io/)

## Документация

См. [dopos.github.io/dcape](https://dopos.github.io/dcape)

## Зависимости

* [linux](https://ubuntu.com/download)
* [docker](https://docs.docker.com/engine/install/ubuntu/)
* `sudo apt -y install git make sed curl jq`

## Примеры использования

### Запуск приложения локально

Требования:

* компьютер с linux, docker и **dcape**
* зарегистрированные (в /etc/hosts или внутреннем DNS) имена для ip компьютера (например - `mysite.dev.lan`, `www.mysite.dev.lan`)

#### Пример для статического сайта и nginx

```bash
$ git clone -b v2 --single-branch --depth 1 https://github.com/dopos/dcape-app-nginx-sample.git
..
$ cd dcape-app-nginx-sample
$ make init up APP_SITE=mysite.dev.lan
..
Creating mysite-dev-lan_www_1 ... done
```

Все готово - `http://mysite.dev.lan/` и `http://www.mysite.dev.lan/` запущены.

### Установка dcape без gitea

Требования:

* компьютер с linux, docker и установленными [зависимостями](#зависимости)
* зарегистрированный в DNS для ip этого компьютера wildcard-домен (например - `*.srv1.domain.tld`)
* `$AUTH_TOKEN` для gitea API

```bash
MY_HOST=${MY_HOST:-srv1.domain.tld}
MY_IP=${MY_IP:-192.168.23.10}
LE_ADMIN=${LE_ADMIN:-admin@domain.tld}
GITEA_URL=${GITEA_URL:-https://git.domain.tld}
GITEA_ORG=${GITEA_ORG:-dcape}
GITEA_USER=${GITEA_USER:-dcapeadmin}

$ git clone -b v2 --single-branch --depth 1 https://github.com/dopos/dcape.git
..
$ cd dcape
$ make install ACME=wild DNS=wild DCAPE_DOMAIN=${MY_HOST} \
  TRAEFIK_ACME_EMAIL=${LE_ADMIN} \
  NARRA_GITEA_ORG=${GITEA_ORG} \
  DRONE_ADMIN=${GITEA_USER} \
  PDNS_LISTEN=${MY_IP}:53 \
  GITEA=${GITEA_URL} \
  AUTH_TOKEN=${$TOKEN}
..
Running dc command: up -d db powerdns traefik narra enfist drone portainer
Dcape URL: https://srv1.domain.tld
------------------------------------------
Creating network "dcape" with driver "bridge"
Creating dcape_narra_1         ... done
Creating dcape_db_1            ... done
Creating dcape_drone-compose_1 ... done
Creating dcape_portainer_1     ... done
Creating dcape_traefik_1       ... done
Creating dcape_drone-rd_1      ... done
Creating dcape_drone_1         ... done
Creating dcape_powerdns_1      ... done
Creating dcape_enfist_1        ... done

```

Все готово - сервер `srv1.domain.tld` готов к деплою приложений, интерфейсы приложений **dcape** доступны по адресу `https://srv1.domain.tld`.

## Использование

dcape Makefile. Application environment commands

### Git commands

#### git-%

run git for every app.
sample:
```
make git-status-s
```

### Docker-compose commands

```
    build-compose   create docker-compose image 
    ps              show stack containers 
    up              (re)start container(s) 
    up-%            start container 
    reup-%          restart container 
    reup            restart container(s) 
    down            stop (and remove) container(s) 
```

### Database commands

```
    psql            exec psql inside db container 
    db-create       create database and user 
    db-drop         drop database and user 
    psql-docker     exec psql inside db container from apps/*/ Example: make psql-docker DCAPE_STACK=yes
    psql-local      run local psql from apps/*/ Example: make psql-local DCAPE_STACK=yes PGPORT=5433
```

### App config storage commands

```
    env-get         get env tag from store, `make env-get TAG=app--config--tag` 
    env-ls          list env tags in store 
    env-set         set env tag in store, `make env-set TAG=app--config--tag` 
```

### OAuth2 setup

```
    oauth2-org-create create VCS org via VCS API 
    oauth2-app-create create OAuth2 app via VCS API 
```

### .env operations

```
    config          generate sample config 
    config-force    generate sample config and rename it to .env 
    config-if       generate sample config and rename it to .env if not exists 
```

### Other

```
    clean-noname    delete unused docker images w/o name (you should use portainer for this)
    clean-volume    delete docker dangling volumes (you should use portainer for this)
    help            list Makefile targets (this is default target)
```

## Переменные

| Имя | По умолчанию | Описание |
| --- | ------------ | -------- |
| DCAPE_DOMAIN | dev.lan | dcape containers hostname domain |
| DCAPE_ROOT | $(PWD) | dcape root directory |
| DCAPE_TAG | dcape | container name prefix |
| DCAPE_ADMIN_USER | dcapeadmin | CICD_ADMIN - CICD admin user<br>GITEA_ADMIN_NAME - Gitea admin user name |
| DCAPE_ADMIN_ORG | dcape | VCS OAuth app owner group<br>* NARRA_GITEA_ORG - user group with access to auth protected resources<br>* config oauth app owner<br>* CICD oauth app owner |
| APPS | - | dcape apps<br>calculated by install<br>used in make only |


## Лицензия

The MIT License (MIT), see [LICENSE](LICENSE).

Copyright (c) 2017-2023 Алексей Коврижкин <lekovr+dopos@gmail.com>
