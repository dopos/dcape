# dcape - Docker composed application environment

**Project status**: beta

[Dcape](https://github.com/dopos/dcape) - это система оркестрации docker-контейнеров для программистов. Она позволяет разворачивать свое или стороннее ПО на локальном компьютере или облачном сервере с помощью всего пары файлов - `Makefile` и `docker-compose.yml`. Это можно увидеть в [структуре проекта](https://github.com/dopos/dcape#Структура-проекта) и [конфигурациях приложений](https://github.com/dopos?q=dcape-app).

## Как это работает

Приложения (исходники своего или конфиги чужого ПО) размещаются на github.com или аналогичном сервисе (в составе **dcape** может быть установлен такой сервис - **gitea**).

Для поддержки сервиса **dcape** репозиторий должен содержать файлы:
* `docker-compose.yml` v2.1, где описана конфигурация контейнеров docker, используемых для сборки и запуска приложений
* `Makefile` с командами создания файла настроек `.env` и управления docker-compose

Файл `.env` c переменными для `docker-compose.yml` и другими настройками приложения не размещается в репозитории, при первом деплое он создается и сохраняется в Хранилище конфигураций. После этого доступ к настройкам копий приложения осуществляется через это хранилище.

Интеграция проекта в **dcape** состоит из двух шагов:
1. Настроить автоматическое обновление (webhook) в репозитории проекта
2. Поместить в хранилище конфигураций настройки проекта с разрешением на деплой (параметр `_CI_HOOK_ENABLED`)

После этого push в репозиторий проекта будет приводить к разворачиванию/обновлению приложения на сервере **dcape**.
См. также: [DEPLOY.md](DEPLOY.md)

## Стек приложений

Текущая версия **dcape** имеет в составе следующие приложения:

* [gitea](https://gitea.io/) ([docker](https://store.docker.com/community/images/gitea/gitea))- веб-интерфейс к git
* [traefik](https://traefik.io/) ([docker](https://hub.docker.com/_/traefik/)) - прокси для доступа к www-сервисам контейнеров по заданному имени с поддержкой сертификатов Let's Encrypt
* [portainer](https://portainer.io/) ([docker](https://hub.docker.com/r/portainer/portainer/)) - управление инфраструктурой docker
* cis ([в составе dcape](https://github.com/dopos/dcape/tree/master/apps/cis)) - статический сайт, в подразделах которого размещены страницы служебных приложений dcape. Для доступа к ним необходимо наличие учетной записи в gitea.

**Служебные приложения dcape:**

* [postgresql](https://www.postgresql.org) ([docker](https://store.docker.com/images/postgres)) - хранение конфигураций приложений и БД, используемая приложениями
* [nginx](https://en.wikipedia.org/wiki/Nginx) ([docker](https://store.docker.com/images/nginx)) - доступ к статическому контенту
* [webhook](https://github.com/adnanh/webhook) ([docker](https://store.docker.com/community/images/dopos/webhook)) - деплой программ по событию из gitea
* [webtail](https://github.com/LeKovr/webtail) ([docker](https://store.docker.com/community/images/lekovr/webtail)) - web-интерфейс к логам контейнеров
* [enfist](https://github.com/pgrpc/pgrpc-sql-enfist) - хранилище файлов .env в postgresql с JSON-RPC интерфейсом [dbrpc](https://github.com/LeKovr/dbrpc) ([docker](https://store.docker.com/community/images/lekovr/dbrpc))
* [narra](https://github.com/dopos/narra) ([docker](https://store.docker.com/community/images/dopos/narra)) - сервис авторизации для nginx через API gitea

**Приложения, для которых доступна конфигурация dcape:**

* [drone](https://github.com/drone/drone) ([docker](https://store.docker.com/community/images/drone/drone)) - сборка и тест приложения в отдельном контейнере
* [mattermost](https://about.mattermost.com/) ([docker](https://store.docker.com/community/images/mattermost/mattermost-prod-app)) - сервис группового общения
* [powerdns](https://www.powerdns.com/) - ([docker](https://store.docker.com/community/images/dopos/powerdns)) DNS-сервер, который хранит описания зон в БД postgresql

[Список конфигураций dcape](https://github.com/dopos?q=dcape-app)

## Зависимости

* linux 64bit (git, make, wget, openssl)
* [docker](https://www.docker.com/)

Для работы с контейнерами в dcape используется образ docker c docker-compose, поэтому отдельной установки docker-compose не требуется.

## Быстрый старт

**Установка на локальный сервер**
```
# настроить wildcard domain *.dev.lan
sudo bash -c 'echo "address=/dev.lan/127.0.0.1" > /etc/NetworkManager/dnsmasq.d/dev.lan.conf'
sudo service network-manager reload

# установить dcape
curl -sSL https://raw.githubusercontent.com/dopos/dcape/master/install.sh | sh -s \
  127.0.0.1 -cape 'DOMAIN=dev.lan TRAEFIK_PORT=81'
```

**Настройка удаленного сервера ip 192.168.0.1 с установкой dcape**
Может быть выполнена сразу после установки ОС (описание настройки - см. [install.sh](install.sh)).
В DNS для адреса 192.168.0.1 должна быть задана запись `A *.your.host`.
```
curl -sSL https://raw.githubusercontent.com/dopos/dcape/master/install.sh | sh -s \
 192.168.0.1 -a op -p 32 -s 1Gb -delntu \
 -cape 'APPS="traefik-acme gitea portainer enfist cis" DOMAIN=your.host TRAEFIK_ACME_EMAIL=admin@your.host'

```

## Управление конфигурациями

Конфигурация любого приложения **dcape** - текстовый файл `.env`, который создается командой `make .env`.
Этот файл используется `make start-hook` для разворачивания приложения и [docker-compose](https://docs.docker.com/compose/) при разворачивании контейнеров приложения.
В части переменных, используемых в `docker-compose.yml`, формат файла должен соответствовать [docker-compose env_file](https://docs.docker.com/compose/compose-file/compose-file-v2/#env_file)

Конфигурации приложений хранятся в БД в виде Key-value хранилища, где ключ формируется из адреса git репозитория (организация--проект--ветка), а значение - содержимое `.env` файла. Доступ к хранилищу закрыт паролем и осуществляется через JSON-RPC прокси dbrpc.

Для управления конфигурациями на удаленном сервере **dcape** используется [dcape-config-cli](https://github.com/dopos/dcape-config-cli).
Примеры команд, доступных после клонирования (git clone) и настройки (make .env) dcape-config-cli:

* `make get TAG=name` - получить из хранилища конфигурацию для тега `name` и сохранить в файл `name.env`
* `make set TAG=name` - загрузить файл `name.env` в хранилище с тегом `name`

## Структура проекта

```
├── apps
│   ├── cis
│   │   ├── docker-compose.inc.yml
│   │   ├── html
│   │   ├── Makefile
│   │   └── nginx.conf
│   ├── enfist
│   │   ├── docker-compose.inc.yml
│   │   ├── Makefile
│   │   └── README.md
│   ├── gitea
│   │   ├── docker-compose.inc.yml
│   │   └── Makefile
│   ├── portainer
│   │   ├── docker-compose.inc.yml
│   │   └── Makefile
│   ├── traefik
│   │   ├── docker-compose.inc.yml
│   │   └── Makefile
│   └── traefik-acme
│       ├── docker-compose.inc.yml
│       └── Makefile
├── DEPLOY.md
├── docker-compose.inc.yml
├── install.sh
├── LICENSE
├── Makefile
└── README.md
```

## Установка

Установка производится на хост с 64bit linux

При установке пакетов потребуется пароль для sudo.

```
# make
which make > /dev/null || sudo apt-get install make

# dcape
cd /opt
git clone https://github.com/dopos/dcape.git
cd dcape

# docker
make deps
```

## Инициализация

На этом этапе задается список приложений, формируется файл настроек **dcape** (файл `.env`) и вспомогательные файлы.
Выбор варианта команды `make init` зависит от требуемой конфигурации сервера.
Доступные варианты (надо выбрать один):

```
# конфигурация локального сайта
make init

# сайт, доступный извне, с сертификатами от Let's Encrypt
make init-master DOMAIN=your.host TRAEFIK_ACME_EMAIL=admin@your.host

# свой список приложений
make init APPS="gitea portainer" DOMAIN=example.com
```

После выполнения `init` надо отредактировать файл `.env`, изменив дефолтные настройки на подходящие.
Также будет создан каталог `var/` для файлов, необходимых для запуска приложений.
Персистентные данные приложений размещаются в `var/data/`, журналы - в `var/log/`.

По готовности файла `.env`, необходимо обработать его командой
```
make apply
```
При этом будут стартованы контейнеры enfist и db (postgresql), созданы БД приложений, загружены необходимые для работы данные.

## Использование

* `make up` - старт приложений

После выполнения этой команды все последующие администрирование сервера производится в интерфейсе portainer.
Вместе с тем, в консоли доступны следующие команды:

* `make down` - остановка и удаление всех контейнеров
* `make dc CMD="up -d cis"` - стартовать контейнер заданного приложения (если не запущен)
* `make dc CMD="rm -f -s cis"`- остановить и удалить контейнер
* `make dc CMD="up -d --force-recreate cis"` - пересоздать и стартовать контейнер и его зависимости
* `make db-create NAME=ENFIST` - создать в postgresql пользователя и БД из настроек enfist
* `make db-drop NAME=ENFIST` - удалить пользователя и БД

### Полезные команды

* `make init-master DOMAIN=your.host TRAEFIK_ACME_EMAIL=admin@your.host` - сформировать .env с заданными значениями
* `docker exec -ti dcape_db_1 pg_dump -U mmost > dump-mmost-170813.sql` - выгрузить дамп БД mmost
* `docker exec -i dcape_db_1 psql -U postgres -f - < dump-all-170813.dmp > imp.log 2>imp.err` - загрузить дампы БД (после `make apply`)

### Обновление файла .env

При обновлении проекта возможно появление новых переменных в .env файле.
Алгоритм обновления .env с сохранением старых настроек:
```
mv .env .env.bak
make init
```
все совпадающие значения будут взяты из .env.bak (т.е. из старого конфига).
Если изменятся номера версий используемых образов docker, будут выведены предупреждения.

Для того, чтобы обновить номера версий образов docker, сохранив остальные настройки, надо подготовить .env.bak, убрав из него номера версий:
```
grep -v "_VER=" .env > .env.bak
mv .env .env.all
rm .env
make init
```

## Предыдущее решение

**Dcape** (Дикейп) - это реинкарнация [consup](https://github.com/LeKovr/consup) (консап). В dcape тот же функционал реализован на основе docker-compose, более продвинутой чем [fidm](https://github.com/LeKovr/fidm) версии [fig](http://www.fig.sh/index.html). В **dcape** не требуется для каждого приложения создавать специальный docker-образ. В большинстве случаев подходит официальный образ приложения с https://hub.docker.com (или https://cloud.docker.com). В остальных случаях используются альтернативные сборки, доступные в этом же реестре.


## Особенности реализации

* для запуска контейнеров достаточно docker и make (docker-compose запускается в контейнере)
* для настройки приложения достаточно двух файлов - `Makefile` и `docker-compose.yml`
* настройки служебных приложений размещены в `apps/*/docker-compose.inc.yml`, все эти файлы средствами `make` копируются в `docker-compose.yml` перед запуском `docker-compose`
* файлы `apps/*/Makefile` содержат две цели:
  * `init` - добавление настроек приложения в файл `.env`
  * `apply` - подготовка БД и данных приложения в `var/data/*/`

## Две и более среды dcape на одном сервере

### Текущее решение

Для второй копии изменить порт в параметре `TRAEFIK_PORT` и использовать traefik (не traefik-acme).

### Планируемое решение

Для 2й и следующих копий реализовать конфигурацию без своего traefik (с подключением основного traefik к сети копии).

## TODO

* [ ] mmost bot: `/cget <name>`, `/cset <name>`, `/cls <mask>` (channel linked to server)
* [ ] flow: PR -> Drone -> post to mmost chat with link to PR
* [ ] webhook: обработка pull request

## Лицензия

The MIT License (MIT), see [LICENSE](LICENSE).

Copyright (c) 2017 Alexey Kovrizhkin <lekovr+dopos@gmail.com>
