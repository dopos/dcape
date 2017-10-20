# Changelog

## [0.11]
Релиз: ??

* Изменено
  * apps/traefik*: в настройки вынесен редирект 80 -> 443
  * apps/traefik теперь не совместим по конфигу с apps/traefik-acme, при переключении необходим `make init`

## [0.10]
Релиз: 2017-10-19

* Изменено
  * apps/cis: добавлено создание каталогов var/apps, var/log в cis-apply
  * apps/cis: изменена версия webtail (0.12)
  * apps/enfist: исправлено обновление sql-пакетов enfist,rpc и их текущие версии
* Добавлено
  * Файл CHANGELOG.md
  * README.md: информация о зависимости (gawk), уточнен блок "Быстрый старт"
  * DEPLOY.md: блоки "Информация для разработчика", "Удаление деплоя"
  * Makefile: поддержка параметров `PG_PORT_LOCAL`, `CFG_BAK`

### Установка обновления
```
git pull
mv .env .env.bak

make init
# Тут будет предупреждение об устаревшей версии webtail - надо изменить на новую в .env

make enfist-apply
# Сообщения "ERROR:  Newest lib version (0.1) loaded already" игнорируем, других ошибок быть не должно

make dc CMD="up -d webtail"
```

## [0.9]
Релиз: 2017-10-16

* Проект готов к ревью
