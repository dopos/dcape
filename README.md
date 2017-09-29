# dcape - Docker composed application environment

**Project status**: beta

Утилита для установки стека приложений с помощью docker-compose.

Цель проекта - с минимальными усилиями развернуть на удаленном сервере (или локальном linux-хосте) стек приложений для разработки ПО
и далее поддерживать разворачивание своего кода.

## Стек приложений

Текущая версия dcape имеет в составе следующие приложения:

* [gitea](https://gitea.io/) - веб-интерфейс к git
* [portainer](https://portainer.io/) - управление инфраструктурой docker
* [traefik](https://traefik.io/) - прокси для доступа к www-сервисам контейнеров по заданному имени (с поддержкой Let's encrypt)
* [cis](https://github.com/dopos/dcape/tree/master/apps/cis) - скрипт обработки webhook и статический сайт, в подразделах которого
размещены защищенные паролем страницы приложений Continuous intergation.

Приложения, используемые в целях Continuous intergation:

* [postgresql](https://www.postgresql.org) - хранение конфигураций приложений и БД, используемая приложениями
* [webhook](https://github.com/adnanh/webhook) - деплой программ по событию из gitea
* [webtail](https://github.com/LeKovr/webtail) - web-интерфейс к логам контейнеров
* [enfist](https://github.com/pgrpc/pgrpc-sql-enfist) - хранилище файлов .env в postgresql с JSON-RPC интерфейсом

Приложения, для которых доступна конфигурация в dcape:

* [drone](https://github.com/drone/drone) - сборка и тест приложения в отдельном контейнере
* [mattermost](https://about.mattermost.com/) - сервис группового общения
* [powerdns](https://www.powerdns.com/) - DNS-сервер, который хранит описания зон в БД postgresql

## Зависимости

* linux 64bit (git, make, wget, openssl)
* [docker](https://www.docker.com/)

## Предыдущее решение

Dcape (Дикейп) - это реинкарнация [consup](https://github.com/LeKovr/consup) (консап). В dcape тот же функционал
реализован на основе docker-compose, более продвинутой версии fig, чем fidm. Это решение проще и не
требует для каждого приложения создавать специальный docker-образ. В большинстве случаев подходит официальный образ приложения
с https://hub.docker.com (или https://cloud.docker.com). В остальных случаях используются альтернативные сборки, доступные в этом же реестре.

## Быстрый старт

Скрипт настройки нового сервера - https://raw.githubusercontent.com/dopos/dcape/master/setup-remote-host.sh

## Установка

Установка производится на хост с 64bit linux

### Установка **make**

Ниже описывается вариант для apt-based ОС (Debian, Ubuntu), в других дистрибутивах установка make и wget производится аналогично.

При установке пакета потребуется пароль для sudo.

```
which make > /dev/null || sudo apt-get install make
```

### Установка **dcape**

```
git clone https://github.com/dopos/dcape.git
cd dcape
```

### Установка **docker**

```
make deps
```

## Инициализация

На этом этапе задается список приложений, формируется шаблон конфигурации (файл `.env`) и вспомогательные файлы.
Выбор варианта команды `make init` зависит от требуемой конфигурации сервера.
Доступные варианты (надо выбрать один):

```
# конфигурация локального сайта
make init

# сайт, доступный извне, с сертификатами от Let's Encrypt
make init-master DOMAIN=example.com

# свой список приложений
make init APPS="gitea mmost portainer" DOMAIN=example.com
```

После этого надо отредактировать файл `.env`, изменив дефолтные настройки на подходящие.
Также будет создан каталог `var` для файлов, необходимых для запуска приложений.
Персистентные данные приложений размещаются в `var/data`, журналы - в `var/log`.

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
* `make dc CMD="up -d mmost"` - стартовать контейнер заданного приложения (если не запущен)
* `make dc CMD="rm -f -s mmost"`- остановить и удалить контейнер
* `make dc CMD="up -d --force-recreate  mmost"` - пересоздать и стартовать контейнер и его зависимости
* `make db-create NAME=MMOST` - создать в postgresql пользователя и БД из настроек mmost
* `make db-drop NAME=MMOST` - удалить пользователя и БД

### Полезные команды

* `make init-master DOMAIN=your.host TRAEFIK_ACME_EMAIL=admin@your.host` - сформировать .env с заданными значениями
* `docker exec -ti dcape_db_1 pg_dump -U mmost > dump-mmost-170813.sql` - выгрузить дамп БД mmost
* `docker exec -i dcape_db_1 psql -U postgres -f - < dump-all-170813.dmp > imp.log 2>imp.err` - загрузить дампы БД (после `make apply`)

### Обновление файла .env

При обновлении проекта появляются новые переменные в .env файле.
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

## Особенности реализации

* определенная совместимость с [consup](https://github.com/LeKovr/consup) сохранена, можно запускать контейнеры оттуда (для этого, в частности, у `consul` параметр `datacenter` имеет значение `consup`) и алгоритм деплоя основан на том же webhook
* для запуска контейнеров достаточно docker и make (docker-compose запускается в контейнере)
* для настройки приложения достаточно двух файлов - `Makefile` и инклюда для `docker-compose.yml`
* настройки контейнеров размещены в `apps/*/docker-compose.inc.yml`, все эти файлы средствами `make` копируются в `docker-compose.yml` перед запуском `docker-compose`
* файлы `apps/*/Makefile` содержат две цели:
  * `init` - добавление настроек приложения в файл `.env`
  * `apply` - подготовка БД и данных приложения в `var/data/*/`

## Две и более среды dcape на одном сервере

### Текущее решение

Изменить порт в параметре `TRAEFIK_PORT` и использовать traefik (не traefik-acme).

### Планируемое решение

Для 2й и следующих копий реализовать конфигурацию без своего traefik (с подключением основного traefik к сети копии).

## TODO

* [ ] CIS login via gitea (в настройках указывать организацию)
* [ ] mmost bot: `/cget <name>`, `/cset <name>`, `/cls <mask>` (channel linked to server)
* [ ] flow: PR -> Drone -> post to mmost chat with link to PR
* [ ] webhook: обработка tag create + pull request

## Лицензия

The MIT License (MIT), see [LICENSE](LICENSE).

Copyright (c) 2017 Alexey Kovrizhkin <lekovr+dopos@gmail.com>
