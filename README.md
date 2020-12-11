# dcape - Docker composed application environment

[![GitHub Release][1]][2]
![GitHub code size in bytes][3]
[![GitHub license][4]][5]

[1]: https://img.shields.io/github/release/dopos/dcape.svg
[2]: https://github.com/dopos/dcape/releases
[3]: https://img.shields.io/github/languages/code-size/dopos/dcape.svg
[4]: https://img.shields.io/github/license/dopos/dcape.svg
[5]: LICENSE

[Dcape](https://github.com/dopos/dcape) - это комплект файлов для [make](https://www.gnu.org/software/make/) и [docker-compose](https://docs.docker.com/compose/), который ставится на сервер и позволяет "по нажатию кнопки" разворачивать и обновлять:

* сторонние приложения из образов docker
* собственные приложения из исходных текстов, размещенных в git

Для поддержки этих процессов, на сервере с помощью **dcape** разворачиваются базовые приложения:

* [traefik](https://traefik.io/) ([image](https://hub.docker.com/_/traefik/)) - агрегация и проксирование www-сервисов развернутых приложений по заданному имени с поддержкой сертификатов Let's Encrypt
* [postgresql](https://www.postgresql.org) ([image](https://hub.docker.com/_/postgres)) - хранение конфигураций всех приложений и размещение баз данных приложений, которым требуется СУБД
* [gitea](https://gitea.io/) ([image](https://hub.docker.com/r/gitea/gitea)) - git совместимый сервис для работы с репозиториями (если используется несколько серверов, разворачивается только на одном)
* [drone](https://github.com/drone) ([image](https://hub.docker.com/r/drone/drone)) - деплой приложений по событию из gitea
* [narra](https://github.com/dopos/narra) ([image](https://hub.docker.com/r/dopos/narra)) - сервис OAuth2 авторизации для учетных записей gitea, используемый для ограничения доступа к приватным ресурсам
* [enfist](https://github.com/apisite/app-enfist) ([image](https://hub.docker.com/r/apisite/enfist)) - хранилище файлов конфигурации в postgresql с доступом через браузер и АПИ
* [powerdns](https://www.powerdns.com/) ([image](https://hub.docker.com/r/psitrax/powerdns)) - DNS-сервер для поддержки wildcard domain сертификатов
* [portainer](https://portainer.io/) ([image](https://hub.docker.com/r/portainer/portainer/)) - интерфейс к [docker](https://www.docker.com/)

## Зачем это нужно

Развертывание **dcape** имеет результатом 2 файла - `docker-compose.yml` и `.env`, которые позволяют командой `make up` запустить весь стек выбранных для конкретного сервера приложений. Все эти приложения доступны на [dockerhub](https://hub.docker.com/) и все нужное для их запуска командой `docker-compose up` может быть подготовлено вручную, однако **dcape** добавляет в процесс подготовки такого решения следующие преимущества:

* файл параметров (`.env`) формируется программно, что позволяет
    * использовать в значениях переменные
    * генерировать необходимые приложениям пароли и токены
    * формировать взаимосвязанные настройки приложений
* файл конфигурации контейнеров (`docker-compose.yml`) формируется программно, что позволяет параметризовать список приложений для каждой инсталляции, в частности
    * если разворачивается группа серверов различного назначения, gitea достаточно развернуть только на одном из них, а на остальных вместо `make init` выполнять `make init GITEA=https://git.domain.tld`
    * если для сервера не нужен SSL (например, в локальной сети), не указывать параметр `ACME`
    * если для сервера не нужен DNS (например, wildcard сертификаты не используются или их поддержка не использует локальный DNS), не указывать параметр `DNS`
* использование `make` позволяет перед стартом приложения выполнять его инициализацию, включая
    * создание БД (и, при необходимости, загрузку дампа БД)
    * формирование файлов конфигураций по шаблонам
    * регистрацию OAuth2 приложений

## Зависимости

* linux 64bit с git, make, sed, curl, jq (тестируем на Ubuntu)
* [docker](http://docker.io)

`docker-compose` используется в **dcape** в формате [docker-образа](https://hub.docker.com/r/docker/compose/), поэтому отдельной установки не требует.

<h2 href="#install">Установка</h2>

Т.к. **dcape** разворачивает несколько независимых сервисов, их имена должны быть прописаны в DNS. Предпочтительным является вариант регистрации wildcard domain, но можно и регистрировать индивидуально.
Пример имен для сервера `srv1.domain.tld`:

* `srv1.domain.tld` - для фронтендов narra, enfist, traefik
* `git.srv1.domain.tld` - для gitea
* `drone.srv1.domain.tld` - для drone
* `port.srv1.domain.tld` - для portainer
* `ns.srv1.domain.tld` - для powerdns

См. также: [DNS setup](README-DNS.md)

### Команды в консоли

```bash
# docker
# см https://docs.docker.com/engine/install/ubuntu/
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt install docker-ce docker-ce-cli containerd.io
usermod -a -G docker $USER

# зависимости
sudo apt-get install make git sed curl jq

# dcape
cd /opt
sudo mkdir dcape && sudo chown $USER dcape
git clone https://github.com/dopos/dcape.git
cd dcape
git checkout -b v2 origin/v2
make init DCAPE_DOMAIN=srv1.domain.tld
make apply
make up
# если gitea локальная - открыть GITEA_URL, завершить инсталляцию и создать токен
# иначе - авторизоваться и создать токен
make gitea-setup TOKEN=... # получить и сохранить в .env *_CLIENT_{ID,KEY}
make up
```

`TOKEN` - ключ АПИ gitea, который создается вручную пользователем, имеющим права на создание
* организации, указанной в параметре `NARRA_GITEA_ORG` (если она не создана ранее)
* OAuth2 приложений narra и drone (их CLIENT_ID и CLIENT_KEY будут сохранены в .env).

`TOKEN` используется однократно при выполнении `make gitea-setup` и нигде не сохраняется

См. также: [Issue 22, Автоматизировать первичную настройку Gitea](https://github.com/dopos/dcape/issues/22)

### Аргументы `make init`

Благодаря использованию `Makefile`, любой параметр **dcape** может быть задан в аргументах команды `make init`, после выполнения которой полный список переменных с их описанием и значениями доступен в файле с именем `.env` (или именем, заданном в параметре `CFG`).

Следующие параметры имеют ключевое значение для конфигурации **dcape**:

`DCAPE_TAG`

* Идентификатор стека приложений, позволяющий изолировать его от других контейнеров docker (в т.ч. и от другой копии стека **dcape** если такая будет запущена на том же сервере)
* Префикс контейнеров стека (значение используется как `COMPOSE_PROJECT_NAME`)

`DCAPE_DOMAIN`

* hostname для базовых приложений (narra, enfist, traefik)
* суффикс по умолчанию для hostname остальных приложений стека

`GITEA`

* значения: `[yes]|<URL>`
* `yes` - добавить в конфигурацию локальный сервер gitea
* `<URL>` - адрес внешнего сервера gitea

`DNS`

* значения: `[no]|yes|wild`
* добавить в конфигурацию локальный сервер powerdns
* `wild` - настроить зону для поддержки wildcard сертификатов letsencrypt

`ACME`

* значения: `[no]|http|wild`
* включить поддержку сертификатов letsencrypt
* `no` - адреса сервисов **dcape** будут начинаться с `http://`, иначе - `https://`
* `wild` - в конфигурацию traefik будет добавлена поддержка сертификатов для домена `*.DCAPE_DOMAIN`

`NARRA_GITEA_ORG`

* username организации gitea, участникам которой будет предоставлен доступ к приватным ресурсам

`DRONE_ADMIN`

* username пользователя gitea, который получит права администратора в drone

См. также:
* Файл конфигурации traefik для сертификатов [только HTTP-01](/apps/traefik/traefik.acme-http.yml) и [HTTP-01 + DNS-01](/apps/traefik/traefik.acme.yml)

При выполнении команды `make apply` соответствующий файл конфигурации traefik копируется в `var/traefik/traefik.yml` с заменой переменных. После этого достаточно в нем закомментировать строку `caServer`, в которой по умолчанию указан адрес тестового сервиса.

Если файл `var/traefik/traefik.yml` существует, **dcape** не производит в нем никаких изменений и его можно изменять по своим потребностям.

### Примеры make init

```bash
# сервер для локального использования
make init

# посмотреть .env без сохранения изменений
make init CFG=tmp$$ DCAPE_VAR=tmp$$-var ACME=wild DNS=wild && less tmp$$ && rm -rf tmp$$*
```

См. также:

* [Traefik setup](https://github.com/dopos/dcape/tree/v2/apps/traefik)
* [Скрипт удаленной настройки сервера и установки dcape](install.sh)

## Что дальше

Для развертывания приложений в среде **dcape** v2 используется drone c образом docker-compose (создается при установке dcape).

## См. также

* [Deploy with Drone](https://github.com/dopos/dcape/tree/v2/apps/drone)
* [Адаптированные для dcape приложения](https://github.com/dopos?q=dcape-app)
* [dcape-config-cli](https://github.com/dopos/dcape-config-cli) - утилита для работы (загрузки,выгрузки, изменения) с конфигурациями запуска в среде **dcape**
* [Актуальный список адаптированных приложений dcape](https://github.com/dopos?q=dcape-app)

## Управление конфигурациями запуска приложений

Конфигурация запуска любого приложения **dcape** - текстовый файл `.env`, который создается командой `make .env`.
Этот файл используется `make start-hook` для разворачивания приложения и [docker-compose](https://docs.docker.com/compose/) для управления контейнерами приложения.
В части переменных, используемых в `docker-compose.yml`, формат файла должен соответствовать [docker-compose env_file](https://docs.docker.com/compose/compose-file/compose-file-v2/#env_file).

Конфигурации запуска приложений хранятся в БД в виде Key-value хранилища, где ключ формируется из адреса git репозитория `organization--name_of_repo--branch` (`организация--проект--ветка`), а значение - содержимое `.env` файла. Доступ к хранилищу закрыт паролем и осуществляется через фронтенд **cis**.

Кроме веб-интерфейса, работа с конфигурациями запуска может осуществляться через [dcape-config-cli](https://github.com/dopos/dcape-config-cli).
Примеры команд, доступных после клонирования (git clone) и настройки (make .env) dcape-config-cli:

* `make get TAG=name` - получить из хранилища конфигурацию для тега `name` и сохранить в файл `name.env`
* `make set TAG=name` - загрузить файл `name.env` в хранилище с тегом `name`

Тег содержит значение равное ключу БД Key-value хранилища `organization--name_of_repo--branch` (`организация--проект--ветка`)


## Использование

* `make up` - старт приложений

После выполнения этой команды все последующее администрирование среды и запущеных сервисов производится в www интерфейсе portainer.
Вместе с тем, в консоли доступны следующие команды:

* `make` - список доступных команд
* `make down` - остановка и удаление всех контейнеров
* `make dc CMD="up -d cis"` - стартовать контейнер заданного приложения (если не запущен)
* `make dc CMD="rm -f -s cis"`- остановить и удалить контейнер
* `make dc CMD="up -d --force-recreate cis"` - пересоздать и стартовать контейнер и его зависимости
* `make db-create NAME=ENFIST` - создать в postgresql пользователя и БД из настроек enfist
* `make db-drop NAME=ENFIST` - удалить пользователя и БД из настроек enfist
* `make apply PG_SOURCE_SUFFIX=-171014` - развернуть проект, используя резервные копии БД, созданные [pg-backup](https://github.com/dopos/dcape-app-pg-backup)

### Обновление файла .env

При обновлении проекта возможно появление новых переменных в `.env` файле.
Алгоритм обновления .env с сохранением старых настроек:

```bash
mv .env .env.bak
make init
```

Другой вариант:

```bash
mv .env .env.1019
make init CFG_BAK=.env.1019
```

Все совпадающие значения будут взяты из `.env.bak` (т.е. из старого конфига).
Если изменятся номера версий используемых образов docker, будут выведены предупреждения.

Для того, чтобы обновить номера версий образов docker, сохранив остальные настройки, надо подготовить `.env.bak`, убрав из него номера версий:

```bash
grep -v "_VER=" .env > .env.bak
mv .env .env.all
make init
```

## Особенности реализации

* для запуска контейнеров достаточно docker и make (docker-compose запускается в контейнере)
* для настройки приложения достаточно двух файлов - `Makefile` и `docker-compose.yml`
* настройки встроенных приложений размещены в `apps/*/docker-compose.inc.yml`, все эти файлы средствами `make` копируются в `docker-compose.yml` перед запуском `docker-compose`
* файлы `var/apps/*/Makefile` содержат две цели (для адаптированных приложений):
  * `init` - добавление настроек приложения в файл `.env`
  * `apply` - подготовка БД и данных приложения в `var/`

## Две и более среды dcape на одном сервере

* для второй копии изменить порты в параметрах `TRAEFIK_LISTEN` и `TRAEFIK_LISTEN_SSL`
* изменить параметр `DCAPE_TAG`

## Предыдущее решение

**Dcape** (Дикейп) v2 отличается от v1 переездом деплоя на drone и сменой версии traefik на v2.
Сам проект - это реинкарнация [consup](https://github.com/LeKovr/consup) (консап). В **dcape** тот же функционал реализован на основе docker-compose, более продвинутой чем [fidm](https://github.com/LeKovr/fidm) версии [fig](http://www.fig.sh/index.html). В **dcape** не требуется для каждого приложения создавать специальный docker-образ. В большинстве случаев подходит официальный образ приложения с [DockerHub](https://hub.docker.com). В остальных случаях используются альтернативные сборки, доступные в этом же реестре.

## Благодарности

* Проекту [docker-compose](https://docs.docker.com/compose/), который научился читать конфиг из файла (что позволило отказаться от [fidm](https://github.com/LeKovr/fidm))
* Проекту [traefik](https://traefik.io/) за возможность на лету подключать контейнеры как виртуальный HTTP-хост (что избавило от необходимости собирать индивидуальные контейнеры [consup](https://github.com/LeKovr/consup))
* Проекту [portainer](https://portainer.io/), который позволил управлять инфраструктурой docker через веб-интерфейс, без логина на сервер по ssh

## Лицензия

The MIT License (MIT), see [LICENSE](LICENSE).

Copyright (c) 2017-2020 Alexey Kovrizhkin <lekovr+dopos@gmail.com>
