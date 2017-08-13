# dcape - Docker composed application environment

Утилита для установки стека приложений с помощью docker-compose.

Дикейп - это реинкарнация [консап](https://github.com/LeKovr/consup). В Дикейп тот же функционал
реализован в соответствии с текущими возможностями инфраструктуры docker. Это решение значительно проще и не
требует для каждого приложения создавать специальный docker-образ. В большинстве случаев подходит официальный образ приложения
с https://hub.docker.com. В остальных случаях используются альтернативные сборки, доступные в этом же реестре.

## Приложения

Текущая версия dcape поддерживает следующие приложения:

* [gitea](https://gitea.io/) - веб-интерфейс к git
* [mattermost](https://about.mattermost.com/) - сервис группового общения
* [portainer](https://portainer.io/) - управление инфраструктурой docker
* [drone](https://github.com/drone/drone) - сборка и тест приложения в отдельном контейнере
* [traefik](https://traefik.io/) - прокси для доступа к www-сервисам контейнеров по заданному имени
* [powerdns](https://www.powerdns.com/) - DNS-сервер, который хранит описания зон в БД postgresql
* cis - статический сайт, в подразделах которого размещены защищенные паролем страницы приложений Continuous intergation

Для приложений, требующих БД, используется контейнер postgresql.

Приложения, используемые в целях Continuous intergation:

* [consul](https://www.consul.io/) - Key-Value хранилище для хранения конфигураций и интерфейс к нему
* [webhook](https://github.com/adnanh/webhook) - деплой программ по событию из gitea
* [webtail](https://github.com/LeKovr/webtail) - web-интерфейс к логам контейнеров

## Зависимости

* linux 64bit (git, make, wget, openssl)
* [docker](https://www.docker.com/)

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
git clone https://github.com/TenderPro/dcape.git
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
При этом будут стартованы контейнеры consul и db (postgresql), созданы БД, загружены необходимые для работы данные.

## Использование

* `make up` - старт приложений

После выполнения этой команды все последующие администрирование сервера производится в интерфейсе portainer.
Вместе с тем, в консоли доступны следующие команды:

* `make down` - остановка и удаление всех контейнеров
* `make dc CMD="up -d mmost"` - стартовать контейнер заданного приложения (если не запущен)
* `make dc CMD="rm -f -s mmost"`- остановить и удалить контейнер
* `make dc CMD="up -d --force-recreate  mmost"` - пересоздать и стартовать контейнер и его зависимости
* `make db-create NAME=mmost` - создать в postgresql пользователя и БД mmost
* `make db-drop NAME=mmost` - удалить пользователя и БД mmost

### Полезные команды

* `make init-master DOMAIN=your.host TRAEFIK_ACME_EMAIL=admin@your.host` - сформировать .env с заданными значениями
* `docker exec -ti dcape_db_1 pg_dump -U mmost > dump-mmost-170813.sql` - выгрузить дамп БД mmost
* `docker exec -i dcape_db_1 psql -U postgres -f - < dump-all-170813.dmp > imp.log 2>imp.err` - загрузить дампы БД (после `make apply`)

## Особенности реализации

* определенная совместимость с [консап](https://github.com/LeKovr/consup) сохранена, здесь можно запускать контейнеры оттуда (для этого, в частности, у `consul` параметр `datacenter` имеет значение `consup`) и алгоритм деплоя основан на том же webhook
* для запуска контейнеров достаточно docker и make (даже docker-compose запускается в контейнере)
* для настройки приложения достаточно двух файлов - `Makefile` и инклюда для `docker-compose.yml`
* настройки контейнеров размещены в `apps/*/docker-compose.inc.yml`, все эти файлы средствами `make` копируются в `docker-compose.yml` перед запуском `docker-compose`
* файлы `apps/*/Makefile` содержат две цели:
  * `init` - добавление настроек приложения в файл `.env`
  * `apply` - подготовка БД и данных приложения в `var/data/*/`

## Лицензия

The MIT License (MIT), see [LICENSE](LICENSE).

Copyright (c) 2017 Tender.Pro
