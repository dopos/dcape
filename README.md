<p align="center">
  <span>Pусский</span> |
  <a href="README.en.md#readme">English</a>
</p>

---

# dopos/dcape

> Деплой приложений с docker-compose и make

[![GitHub Release][1]][2]
![GitHub code size in bytes][3]
[![GitHub license][4]][5]

[1]: https://img.shields.io/github/release/dopos/dcape.svg
[2]: https://github.com/dopos/dcape/releases
[3]: https://img.shields.io/github/languages/code-size/dopos/dcape.svg
[4]: https://img.shields.io/github/license/dopos/dcape.svg
[5]: LICENSE

[Dcape](https://github.com/dopos/dcape) - это инструмент для развёртывания [docker](https://www.docker.com/)-приложений по технологии [GitOps](https://www.gitops.tech/), который с помощью [make](https://www.gnu.org/software/make/) и [docker-compose](https://docs.docker.com/compose/), позволяет решить следующие задачи:

* командами `make up` запускать приложения, использующие
  * **общий порт** (например 80)
  * **БД**
* командой `git push` **удаленно разворачивать приложения** на одном или нескольких компьютерах
* через АПИ или web-интерфейс **управлять конфигурациями** приложений
* **ограничивать** заданной группой пользователей **доступ** к интерфейсам управления используемым ПО
* обслуживать работу с letsencrypt сертификатами **wildcard-доменов**
* **управлять инфраструктурой docker**

**Dcape** представляет собой набор **Makefile** и настроек, позволяющий подготовить и развернуть на сервере комплекс согласованных между собой приложений.

**Dcape** не является постоянно работающим сервисом.

## Приложения

Для решения поставленных задач могут быть использованы docker-образы следующих приложений:

* **общий порт**  - [traefik](https://traefik.io/)
  * **БД** - [postgresql](https://www.postgresql.org)
* **удаленно разворачивать приложения** - [Woodpecker CI](https://woodpecker-ci.org/) (на каждом компьютере) и на каком-то одном - [gitea](https://gitea.io/) (или аналог)
* **управлять конфигурациями** - [enfist](https://github.com/apisite/app-enfist)
* **ограничивать доступ** - [narra](https://github.com/dopos/narra), в качестве группы пользователей используется организация [gitea](https://gitea.io/)
* **wildcard-домены** - [powerdns](https://www.powerdns.com/)
* **управлять инфраструктурой docker** - [portainer](https://portainer.io/)

<a name="why"></a>

## Зачем dcape?

Все эти приложения распространяются независимо от **dcape** и могут быть развернуты самостоятельно.
При этом, в процессе деплоя может потребоваться выполнить
* собственную настройку приложения (БД, первичные данные...)
* настройку взаимодействия (адреса для запросов, ключи доступа...)

В максимальном варианте процесс настройки всего комплекса приложений включает задание значений для ~90 параметров. В **dcape** это количество [уменьшено до 3х](#install-full) для некоторых конфигураций.

Примерную схему взаимодействий между приложениями можно посмотреть [тут](charts.md#arch)

**Dcape** позволяет упростить процесс развертывания следующим образом

* многие параметры можно рассчитать на основе уже известных
* для определения значений параметра можно вызвать внешнюю программу (например, `KEY ?= $(shell openssl rand -hex 16; echo)`)
* для определения значений параметра и кода можно использовать программные конструкции (например, `ifneq ($(AUTH_TOKEN),)`)
* `make` позволяет любой параметр переопределить в строке вызова
* инструменты **dcape** доступны при деплое других приложений (см [dcape-app-template](https://github.com/dopos/dcape-app-template) )
* исходный код **dcape** с учетом настроек всех 8 сервисов - это
  * 10 `Makefile`, всего 485 строк
  * 17 `YAML`, всего 502 строки

## Документация

См. [dopos.github.io/dcape](https://dopos.github.io/dcape)

<a name="requirements"></a>

## Зависимости

* [linux](https://ubuntu.com/download) + `sudo apt -y install git make sed curl jq вшп`
* [docker](https://docs.docker.com/engine/install/ubuntu/) + `sudo apt -y install docker-compose-plugin`

## Примеры использования

### Запуск приложения локально

Требования:

* компьютер с linux, docker и **dcape**
* зарегистрированные (в /etc/hosts или внутреннем DNS) имена для ip компьютера (например - `mysite.dev.lan`, `www.mysite.dev.lan`)

#### Пример для статического сайта и nginx

```bash
git clone https://github.com/dopos/dcape-app-nginx-sample.git
cd dcape-app-nginx-sample
make config-if
# <edit .env>
make up
```

Все готово - `http://mysite.dev.lan/` и `http://www.mysite.dev.lan/` запущены.

### Запуск приложения удаленно

* [Диаграмма первичного развертывания](charts.md#install-app-1st-deploy)
* [Диаграмма обновления приложения](charts.md#update)

### Установка dcape

Требования:

* компьютер с linux, docker и установленными [зависимостями](#requirements)
* зарегистрированный в DNS для ip этого компьютера wildcard-домен (например - `*.srv1.domain.tld`)

<a name="install-full"></a>

#### Конфигурация с локальным gitea

```bash
MY_HOST=demo.dcape.ru
MY_IP=${MY_IP:-192.168.23.10}
LE_ADMIN=admin@dcape.ru

git clone https://github.com/dopos/dcape.git
cd dcape
make install ACME=wild DNS=wild DCAPE_DOMAIN=${MY_HOST} \
  TRAEFIK_ACME_EMAIL=${LE_ADMIN} PDNS_LISTEN=${MY_IP}:53
make echo-gitea-admin-pass
```

#### Конфигурация с удаленным gitea

Дополнительные требования для регистрации приложений на удаленном gitea

* `$AUTH_TOKEN` для gitea API


```bash
MY_HOST=${MY_HOST:-srv1.domain.tld}
LE_ADMIN=${LE_ADMIN:-admin@domain.tld}
GITEA_URL=${GITEA_URL:-https://git.domain.tld}
GITEA_ORG=${GITEA_ORG:-dcape}
GITEA_USER=${GITEA_USER:-dcapeadmin}

git clone https://github.com/dopos/dcape.git
cd dcape
make install ACME=wild DNS=wild DCAPE_DOMAIN=${MY_HOST} \
  TRAEFIK_ACME_EMAIL=${LE_ADMIN} \
  NARRA_GITEA_ORG=${GITEA_ORG} \
  DRONE_ADMIN=${GITEA_USER} \
  PDNS_LISTEN=${MY_IP}:53 \
  GITEA=${GITEA_URL} \
  AUTH_TOKEN=${AUTH_TOKEN}
make echo-gitea-admin-pass
```

Все готово - сервер `srv1.domain.tld` готов к деплою приложений, интерфейсы приложений **dcape** доступны по адресу `https://srv1.domain.tld`.

## Использование

Команды (targets) Makefile. Актуальный список: `make[ help]`.

### Git commands

```
    git-%           run git for every app. Sample: make git-status-s
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
    psql-docker     exec psql inside db container from apps. Example: make psql-docker DCAPE_STACK=yes
    psql-local      run local psql from apps. Example: make psql-local DCAPE_STACK=yes PGPORT=5433
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
    echo-%          print config var. Sample: make echo-gitea-admin-pass
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
